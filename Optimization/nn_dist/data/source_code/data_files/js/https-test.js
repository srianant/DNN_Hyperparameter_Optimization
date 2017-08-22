/**
 * Copyright 2016 Google Inc. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
'use strict';

/* eslint-env mocha */

const HTTPSGather = require('../../../gather/gatherers/https');
const assert = require('assert');
let httpsGather;

describe('HTTPS gatherer', () => {
  // Reset the Gatherer before each test.
  beforeEach(() => {
    httpsGather = new HTTPSGather();
  });

  it('returns an artifact', () => {
    return httpsGather.afterPass({
      driver: {
        getSecurityState() {
          return Promise.resolve({
            schemeIsCryptographic: true
          });
        }
      }
    }).then(_ => {
      assert.deepEqual(httpsGather.artifact.value, true);
    });
  });

  it('handles driver failure', () => {
    return httpsGather.afterPass({
      driver: {
        getSecurityState() {
          return Promise.reject('such a fail');
        }
      }
    }).then(_ => {
      assert.equal(httpsGather.artifact.value, false);
      assert.ok(httpsGather.artifact.debugString);
    });
  });

  it('handles driver timeout', () => {
    const fastTimeout = 50;
    const slowResolve = 200;
    let artifact;

    return httpsGather.afterPass({
      driver: {
        getSecurityState() {
          return new Promise((resolve, reject) => {
            // Resolve slowly, after the timeout for waiting on the security
            // state has fired.
            setTimeout(_ => resolve({
              schemeIsCryptographic: true
            }), slowResolve);
          });
        }
      },

      _testTimeout: fastTimeout
    }).then(_ => {
      artifact = httpsGather.artifact;
      assert.equal(artifact.value, false);
      assert.ok(artifact.debugString);

      // Wait until after slow resolve to ensure artifact value didn't change.
      return new Promise((resolve, reject) => {
        setTimeout(resolve, slowResolve);
      });
    }).then(_ => {
      assert.deepStrictEqual(httpsGather.artifact, artifact);
    });
  });
});
