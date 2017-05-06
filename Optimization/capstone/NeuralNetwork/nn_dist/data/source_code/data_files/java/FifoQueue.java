package queue;
import java.util.*;

public class FifoQueue<E> extends AbstractQueue<E> 
implements Queue<E> {
	private QueueNode<E> last;
	private int size;

	public FifoQueue() {
        size = 0;
	}

	/**	
	 * Returns an iterator over the elements in this queue
	 * @return an iterator over the elements in this queue
	 */	
	public Iterator<E> iterator() {
        return new QueueIterator();
	}

    private class QueueIterator implements Iterator<E> {
        private QueueNode<E> pos;
        /* Konstruktor */
        private QueueIterator() {
            pos = last;
        }

        public boolean hasNext() {
            return pos != null;
        }

        public E next() {
            if(!hasNext()) {
                throw new NoSuchElementException();
            }
            QueueNode<E> nxt = pos.next;
            if(pos.next == last.next || last.next == last) {
                pos = null;
            } else {
                pos = pos.next;
            }
            return nxt.element;
        }

        public void remove() {
            throw new UnsupportedOperationException();
        }
    }

	/**	
	 * Returns the number of elements in this queue
	 * @return the number of elements in this queue
	 */
	public int size() {		
		return size;
	}

	/**	
	 * Inserts the specified element into this queue, if possible
	 * post:	The specified element is added to the rear of this queue
	 * @param	x the element to insert
	 * @return	true if it was possible to add the element 
	 * 			to this queue, else false
	 */
	public boolean offer(E x) {
        QueueNode<E> new_last = new QueueNode<E>(x);
        if(size != 0) {
            new_last.next = last.next;
            last.next = new_last;
        } else {
            new_last.next = new_last;
        }
        last = new_last;
        size++;
        return true;
	}

	/**	
	 * Retrieves and removes the head of this queue, 
	 * or null if this queue is empty.
	 * post:	the head of the queue is removed if it was not empty
	 * @return 	the head of this queue, or null if the queue is empty 
	 */
	public E poll() {
        if(size == 0) {
            return null;
        }
        QueueNode<E> first = last.next;
        last.next = first.next;
        size--;
        return first.element;
	}

	/**	
	 * Retrieves, but does not remove, the head of this queue, 
	 * returning null if this queue is empty
	 * @return 	the head element of this queue, or null 
	 * 			if this queue is empty
	 */
	public E peek() {
        if(size == 0) {
            return null;
        }
        return last.next.element;
	}

    /**
     * Appends the specified queue to this queue
     * post: all elements from the specified queue are appended
     * to this queue. The specified queue (q) is empty
     * @param q the queue to append
     */
    public void append(FifoQueue<E> q) {
        while(q.size() != 0) {
            offer(q.poll());
        }
    }


	private static class QueueNode<E> {
		E element;
		QueueNode<E> next;

		private QueueNode(E x) {
			element = x;
			next = null;
		}

	}

}
