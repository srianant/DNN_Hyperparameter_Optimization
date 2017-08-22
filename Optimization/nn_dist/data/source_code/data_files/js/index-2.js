/*/
Copyright (c) 1637, Blaise Pascal
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors
   may be used to endorse or promote products derived from this software without
   specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
/*/
function C(x, y, z) {
	if(x>y) {
		for(var i=0; i<10; ++i) {
			if(z>i) {
				if(i>z) {
					z = x+y+i;
				}
			}
		}
	}
	return z;
}

function B(v1, v2) {
	if(v1 > v2) {
		function A(n, m) {
			return [m, n];
		}
		var tmp = A(v1, v2);
		v1 = tmp[0];
		v2 = tmp[1];
	}
	return [v1, v2];
}

if(C(1, 2, 3)>10) {
	console.log(B(1, 2));
} else {
	console.log(B(8, 9));
}

D = function (x, y, z) {
	if(x>y) {
		for(var i=0; i<10; ++i) {
			if(z>i) {
				if(i>z) {
					z = x+y+i;
				}
			}
		}
	}
	return z;
}

E = function (v1, v2) {
	if(v1 > v2) {
		F = function (n, m) {
			return [m, n];
		}
		var tmp = A(v1, v2);
		v1 = tmp[0];
		v2 = tmp[1];
	}
	return [v1, v2];
}


