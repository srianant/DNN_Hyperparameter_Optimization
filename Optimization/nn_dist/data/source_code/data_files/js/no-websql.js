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
 * @fileoverview Audit a page to ensure that it does not open a database using
 * the WebSQL API.
 */

'use strict';

const Audit = require('../audit');

class NoWebSQLAudit extends Audit {

  /**
   * @return {!AuditMeta}
   */
  static get meta() {
    return {
      category: 'Offline',
      name: 'no-websql',
      description: 'Site is not using WebSQL DB.',
      helpText: 'Web SQL Database is <a href="https://dev.w3.org/html5/webdatabase/" target="_blank">deprecated</a>. Consider implementing an offline solution using <a href="https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API/Using_IndexedDB" target="_blank">IndexedDB</a>.',
      requiredArtifacts: ['WebSQL']
    };
  }

  /**
   * @param {!Artifacts} artifacts
   * @return {!AuditResult}
   */
  static audit(artifacts) {
    if (typeof artifacts.WebSQL === 'undefined' ||
        artifacts.WebSQL.database === -1) {
      return NoWebSQLAudit.generateAuditResult({
        rawValue: -1,
        debugString: (artifacts.WebSQL ?
            artifacts.WebSQL.debugString : 'WebSQL gatherer did not run')
      });
    }

    const db = artifacts.WebSQL.database;
    const displayValue = (db && db.database ?
        `db name: ${db.database.name}, version: ${db.database.version}` : '');

    return NoWebSQLAudit.generateAuditResult({
      rawValue: !db,
      displayValue: displayValue
    });
  }
}

module.exports = NoWebSQLAudit;
