RaisesArbitraryException = 1
_ = A::B # Autoloading recursion, also expected to be watched and discarded.

raise Exception, "arbitray exception message"
