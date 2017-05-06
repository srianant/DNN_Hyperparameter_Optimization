"""
    File name         : nn_custom_rnn.py
    File Description  : Deep Neural Network Custom Class Using Tensorflow
    File Version      : 1.0
    Author            : Srini Ananthakrishnan and Michael Rinehart
    Date created      : 04/19/2017
    Date last modified: 05/04/2017
    Python Version    : 3.x
    Tensorflow Version: 1.0.1
"""

# import packages
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import os
import sys
import json
import re
import numpy as np
import tensorflow as tf
from tensorflow.python.ops import rnn
from tensorflow.python.ops import nn_ops

# macro to parse regular expression
_PARSER = re.compile('[a-zA-Z0-9]+|[^a-zA-Z0-9 ]')

class CustomNN(object):
    """Custom class to build any neural network
    Example below builds RNN to classify source code language
    Functionality includes: 
        - build tensorflow recurrent neural network model
        - train network and optimize loss function
    """

    def __init__(self, logging):
        """Initializes a NeuralNetwork instance
        """
        self.logging = logging
        self.costs = []
        self.error_rate = []
        pass


    def _read_kws_delims(self, load_dir):
        """Read dictionary keywords and delimeteres
        Args:
            load_dir: Directory of json file of language keywords
        Variables Used:
            keywords - dictionary of keywords and their index positions for the input vector
            delimeteres - dictionary of delimeters and their index positions for the input vector
            N - input dimensionality
        Returns:
             None
        """

        kw_fname = "%s/keywords.json"%load_dir
        self.logging.info("keywords file:%s",kw_fname)
        delimeters = ["(", ")", "{", "}", "[", "]", "<", ">", "+", "-", "=", "\"", "*", "/",
                      ".", ",", "!", "@", "%", "^", "&", "|", ";", ":", "?"]
        with open(kw_fname, 'r') as f:
            language_kws_str = f.read().lower()
            if language_kws_str == '':  # debugging
                language_kws = {
                    'cpp': {
                        'keywords': ['for', 'if', 'null', 'int', 'public', 'private', 'include'],
                    },
                    'java': {
                        'keywords': ['for', 'if', 'null', 'int', 'public', 'private', 'static', 'import'],
                    }
                }
            else:
                language_kws = json.loads(language_kws_str)

        keywords = dict()
        for language in language_kws:
            for kw in language_kws[language]['keywords']:
                if kw not in keywords:
                    keywords[kw] = len(keywords)

        delimeters = {delim: idx + len(keywords) for idx, delim in enumerate(delimeters)}

        N = len(keywords) + len(delimeters) + 1

        self.keywords =  keywords
        self.delimeters = delimeters
        self.N = N
        self.logging.info("keywords:%d",len(self.keywords))
        self.logging.info("delimeters:%d",len(self.delimeters))
        self.logging.info("N:%d",self.N)


    def token_to_vector(self, token, v=None):
        if v is None:
            v = np.zeros(self.N)
        if token in self.keywords:
            v[self.keywords[token]] = 1.
        elif token in self.delimeters:
            v[self.delimeters[token]] = 1.
        else:
            v[-1] = 1.
        return v


    def parse_string(self, s):
        """
        Parses a string so that we can recognize
        """
        return [s[result.start():result.end()] for result in _PARSER.finditer(s)]


    def _read_data(self, load_dir):
        """
        Source code is assumed to be split into the following folders:
        source_code/
           [language_1]/
           [language_2]/
           ...
           [language_M]/
           NONE/
        where M is the number of languages and 'NONE' is any optional purely negative training data. Subfolders below the 
        top-level are read but not labeled further.
        """
        data_folder = "%s/data_files"%load_dir
        self.logging.info('loading data from...:%s',data_folder)
        # Generate parsed data for each language
        n_files = 0
        language_folders = os.listdir(data_folder)
        raw_data = {language: [] for language in language_folders}
        for language in language_folders:
            self.logging.info('Reading %s...' % language)
            lanaguage_folder = os.path.join(data_folder, language)
            for path, subdir, fnames in os.walk(lanaguage_folder):
                r_sample = 1 if len(fnames) < 2000 else 2000. / len(fnames)
                n_files = 0
                for fname in (os.path.join(path, f) for f in fnames):
                    if np.random.uniform() > r_sample: continue
                    if os.path.isdir(fname): continue
                    with open(fname, 'r', encoding='iso-8859-1') as f:
                        text = f.read()[0:50000]
                        if len(text) > 0:
                            n_files += 1
                            raw_data[language].append(text)
            self.logging.info(' %d files processed', n_files)

        self.logging.info('\n')
        language_data = {}
        for language in language_folders:
            self.logging.info('Parsing %s...',language)
            language_data[language] = [self.parse_string(s) for s in raw_data[language]]

        # Number of labels (including NONE if present)
        M = len(language_folders)

        # Map each language to an index for labeling
        languages = {}
        has_none = False
        for language in language_folders:
            if language != 'NONE':
                languages[language] = len(languages)
            else:
                has_none = True
        if has_none:
            languages['NONE'] = len(languages)

        self.language_data = language_data
        self.language_indices = languages
        self.M = M


    def build_model(self, epoch_config):
        """
        Builds the RNN-based classifier. There are two placeholders in the graph:

        Args:
            FLAGS: Macro dictionary contains user params and some defaults
            epoch_config: epoch configuration
        
        Variables Used:
            - sequences : Batch of inputs sequences over time
                Tensor of size BxTxN where B is the batch size, T is the (maximum) sequence length for all inputs in the
                batch, and N is the dimensionality of the input vector so that:
                    sequences[b,t,:] = input vector at time t for batch b

            - targets : Target classifications for each batch
                Tensor of size B B is the batch size so that:
                    labels[b] == m if the b^th batch is classified as m.

            Because these placeholders are inherent to the graph, they are returned by this function. The loss and
            outputs over time are provided as well.

            n: int Input dimension
            s: int or int[] State dimension. Can use a list to stack RNNs.
            m: int Number of output target classes
        Returns:
            None.
            Save: Tensorflow variables & placeholders - sequences, initial states, targets, 
                                                        loss value, and final states
        """

        # Read keywords and delimeters
        self._read_kws_delims(epoch_config['load_data_dir'])

        # Read source code data
        self._read_data(epoch_config['load_data_dir'])

        n = self.N
        m = self.M
        s = epoch_config['rnn_state_dim']

        if isinstance(s, list) or isinstance(s, tuple):
            n_layers = len(s)
        else:
            n_layers = 1
            s = [s, ]

        # Global iteration steps
        global_step = tf.Variable(0, name="global_step", trainable=False)

        # Batches of input sequences
        sequences = tf.placeholder(tf.float32, [None, None, n])  # b x t x n

        # Create a stacked LSTM
        final_states = [None] * n_layers
        initial_states = [None] * n_layers
        lstm_input = sequences
        for l in range(n_layers):
            with tf.variable_scope('layer%d' % l):
                # Create the LSTM Cell. This is not a node in the graph but rather a definition
                # that will be used to instanitate a RNN node.
                lstm_cell = tf.contrib.rnn.BasicLSTMCell(s[l], state_is_tuple=True)

                # Our initial states are
                initial_states[l] = tf.placeholder(tf.float32, [2, None, s[l]])  # 2 x b x s
                # initial_state = tf.unpack(initial_states[l], num=2, axis=0)
                initial_state = tf.unstack(initial_states[l], num=2, axis=0)
                initial_state = tf.contrib.rnn.LSTMStateTuple(initial_state[0], initial_state[1])

                # Create the RNN node from the LSTM cell. We'll use the final output as the input to a classifier
                lstm_output, lstm_state = rnn.dynamic_rnn(lstm_cell, lstm_input, initial_state=initial_state,
                                                          dtype=tf.float32)
                lstm_input = lstm_output
                # final_states[l] = tf.pack(lstm_state, axis=0)  # [b x s, b x s] => 2 x b x s
                final_states[l] = tf.stack(lstm_state, axis=0)  # [b x s, b x s] => 2 x b x s

        final_output = lstm_output[:, -1, :]  # Output at the final time: b x s
        final_output = tf.transpose(final_output, perm=[1, 0])  # s x b

        # Classification logits
        classifier_weights = tf.Variable(tf.random_normal([m, s[-1]], stddev=0.1))  # m x s
        classifier_bias = tf.Variable(tf.random_normal([m, 1], stddev=0.1))  # m
        classifier_logit_output = tf.matmul(classifier_weights, final_output) + classifier_bias  # m x b
        classifier_logit_output = tf.transpose(classifier_logit_output, [1, 0])  # b x m

        # Targets to match
        targets = tf.placeholder(tf.int64, [None])  # b

        # Loss - use of "sparse_softmax_..." means that the labels are integers, not indicator vectors
        summand = nn_ops.sparse_softmax_cross_entropy_with_logits(logits=classifier_logit_output, labels=targets)
        loss = tf.reduce_sum(summand)

        # Generate classifications for basic comparison
        classifications = tf.arg_max(classifier_logit_output, 1)

        # FIX: Add changes to between the graph (sync_replica)
        self.optimizer = tf.train.AdamOptimizer(learning_rate=epoch_config['learning_rate']).minimize(loss, global_step=global_step)

        self.sequences_placeholder = sequences
        self.initial_states_placeholder = initial_states
        self.target_placeholder = targets
        self.loss = loss
        self.classifications = classifications
        self.final_states = final_states

        # return sequences, initial_states, targets, loss, classifications, final_states

    def make_batch(self):
        """
        Generates a batch of data and labels

        Args:
            None
        Variables used:
            labeled_sequences: dict Dictionary of the form labeled_sequences[label] = list of sequences of tokens
            label_indices: dict Maps labels to integer indices
            batch_size: int Number of sequences in the batch
            sequence_length: int Maximum length of the traning sequences to generate
            input_size: int Dimension of the input vector
        Returns: 
            sequences and labels appropriate for the placeholders from build_rnn()
        """

        labeled_sequences = self.language_data
        label_indices = self.language_indices
        batch_size = self.batch_size
        sequence_length = self.seq_length
        input_size = self.N

        # Original labels for debugging
        labels = np.random.choice(list(labeled_sequences.keys()), size=batch_size)

        # Numeric labels for the RNN
        numeric_labels = np.array([label_indices[label] for label in labels])

        # Build the input sequence
        vector_sequences = np.zeros((batch_size, sequence_length, input_size))
        sequences = [None] * batch_size
        for b in range(batch_size):
            label = labels[b]
            sequences_for_label = labeled_sequences[label]
            if len(sequences_for_label) == 0:
                sys.stderr.write('No sequences for %s' % label)
                b -= 1
                continue
            seq_idx = np.random.randint(0, len(sequences_for_label))
            full_sequence = sequences_for_label[seq_idx]

            start_idx = np.random.randint(0, max(1, len(full_sequence) - 1))
            end_idx = start_idx + sequence_length
            sequence = full_sequence[start_idx:end_idx]
            for t, token in enumerate(sequence):
                self.token_to_vector(token, vector_sequences[b, t, :])  # Vector version of the sequence for the RNN
            sequences[b] = sequence  # The original sequence for debugging

        return vector_sequences, numeric_labels, sequences, labels


    def train_model(self, mon_sess, epoch_config):

        self.batch_size = epoch_config['batch_size']
        self.seq_length = epoch_config['rnn_max_seq_length']
        STATE_SIZE = epoch_config['rnn_state_dim']
        N_LAYERS = len(STATE_SIZE)

        # Generate the initial state to feed into the graph
        _feed_dict_initial_states = \
            {self.initial_states_placeholder[l]: np.zeros((2, self.batch_size, STATE_SIZE[l])) for l in range(N_LAYERS)}

        # Generate data to feed into the graph
        _vector_sequences, _numeric_labels, _, _ = self.make_batch()
        _feed_dict_sequences = {self.sequences_placeholder: _vector_sequences}
        _feed_dict_target = {self.target_placeholder: _numeric_labels}

        # Combine the feeds into a single feed
        _feed_dict = dict(_feed_dict_sequences.items()).copy()
        _feed_dict.update(_feed_dict_initial_states.items())
        _feed_dict.update(_feed_dict_target.items())

        # Run the graph's optimization node for a few iterations and save the iteration results
        _, _loss, _classifications = mon_sess.run([self.optimizer, self.loss, self.classifications],
                                                       feed_dict=_feed_dict)
        avg_loss = _loss / self.batch_size

        _error_rate = sum(_numeric_labels != _classifications) / float(self.batch_size)

        # Publish loss and error_rate for the iteration
        self.costs.append(avg_loss)
        self.error_rate.append(_error_rate)

        return self.costs


