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
'use strict';

/* global caches */

const Gatherer = require('./gatherer');

// This is run in the page, not Lighthouse itself.
/* istanbul ignore next */
function getCacheContents() {
  // Get every cache by name.
  return caches.keys()

      // Open each one.
      .then(cacheNames => Promise.all(cacheNames.map(cacheName => caches.open(cacheName))))

      .then(caches => {
        const requests = [];

        // Take each cache and get any requests is contains, and bounce each one down to its URL.
        return Promise.all(caches.map(cache => {
          return cache.keys()
              .then(reqs => {
                requests.push(...reqs.map(r => r.url));
              });
        })).then(_ => {
          return requests;
        });
      });
}

class CacheContents extends Gatherer {
  static _error(errorString) {
    return {
      raw: undefined,
      value: undefined,
      debugString: errorString
    };
  }

  afterPass(options) {
    const driver = options.driver;

    return driver
        .evaluateAsync(`(${getCacheContents.toString()}())`)
        .then(returnedValue => {
          if (!returnedValue) {
            this.artifact = CacheContents._error('Unable to retrieve cache contents');
            return;
          }
          this.artifact = returnedValue;
        }, _ => {
          this.artifact = CacheContents._error('Unable to retrieve cache contents');
        });
  }
}

module.exports = CacheContents;
