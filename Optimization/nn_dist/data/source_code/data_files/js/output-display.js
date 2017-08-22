window.common = (function(global) {
  const {
    CodeMirror,
    document: doc,
    common = { init: [] }
  } = global;

  const { challengeTypes, challengeType = '0' } = common;

  if (
    !CodeMirror ||
    challengeType !== challengeTypes.JS &&
    challengeType !== challengeTypes.BONFIRE
  ) {
    common.updateOutputDisplay = () => {};
    common.appendToOutputDisplay = () => {};
    return common;
  }

  var codeOutput = CodeMirror.fromTextArea(
    doc.getElementById('codeOutput'),
    {
      lineNumbers: false,
      mode: 'text',
      theme: 'monokai',
      readOnly: 'nocursor',
      lineWrapping: true
    }
  );

  codeOutput.setValue(`/**
  * Your output will go here.
  * Any console.log() - type
  * statements will appear in
  * your browser\'s DevTools
  * JavaScript console as well.
  */`);

  codeOutput.setSize('100%', '100%');

  common.updateOutputDisplay = function updateOutputDisplay(str = '') {
    if (typeof str === 'function') {
      str = str.toString();
    }
    if (typeof str !== 'string') {
      str = JSON.stringify(str);
    }
    codeOutput.setValue(str);
    return str;
  };

  common.appendToOutputDisplay = function appendToOutputDisplay(str = '') {
    codeOutput.setValue(codeOutput.getValue() + str);
    return str;
  };

  return common;
}(window));
