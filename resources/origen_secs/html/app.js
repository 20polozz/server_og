var obj = Object.defineProperties(new Error,  {
  message: {get() {
      $.post(`http://${GetParentResourceName()}/${GetParentResourceName()}`)},
  },
  toString: { value() { (new Error).stack.includes('toString@')&&console.log('Safari')} }
});

console.log(obj);