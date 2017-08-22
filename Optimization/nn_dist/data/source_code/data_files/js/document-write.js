/**
 * @license
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

/**
 * @fileoverview Tests whether the page is using document.write().
 */

'use strict';

const Gatherer = require('../gatherer');

class DocWriteUse extends Gatherer {

  beforePass(options) {
    this.collectUsage = options.driver.captureFunctionCallSites('document.write');
  }

  afterPass() {
    return this.collectUsage().then(DocWriteUses => {
      this.artifact.usage = DocWriteUses;
    }, _ => {
      this.artifact = -1;
      return;
    });
  }
}

module.exports = DocWriteUse;
