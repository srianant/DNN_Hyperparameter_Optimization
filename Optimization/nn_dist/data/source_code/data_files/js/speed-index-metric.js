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

const Audit = require('./audit');
const TracingProcessor = require('../lib/traces/tracing-processor');
const Formatter = require('../formatters/formatter');

// Parameters (in ms) for log-normal CDF scoring. To see the curve:
// https://www.desmos.com/calculator/mdgjzchijg
const SCORING_POINT_OF_DIMINISHING_RETURNS = 1250;
const SCORING_MEDIAN = 5500;

class SpeedIndexMetric extends Audit {
  /**
   * @return {!AuditMeta}
   */
  static get meta() {
    return {
      category: 'Performance',
      name: 'speed-index-metric',
      description: 'Perceptual Speed Index',
      optimalValue: SCORING_POINT_OF_DIMINISHING_RETURNS.toLocaleString(),
      requiredArtifacts: ['traceContents']
    };
  }

  /**
   * Audits the page to give a score for the Speed Index.
   * @see  https://github.com/GoogleChrome/lighthouse/issues/197
   * @param {!Artifacts} artifacts The artifacts from the gather phase.
   * @return {!Promise<!AuditResult>} The score from the audit, ranging from 0-100.
   */
  static audit(artifacts) {
    const trace = artifacts.traces[this.DEFAULT_PASS];
    if (typeof trace === 'undefined') {
      return SpeedIndexMetric.generateAuditResult({
        rawValue: -1,
        debugString: 'No trace found to generate screenshots'
      });
    }

    // run speedline
    return artifacts.requestSpeedline(trace).then(speedline => {
      if (speedline.frames.length === 0) {
        return SpeedIndexMetric.generateAuditResult({
          rawValue: -1,
          debugString: 'Trace unable to find visual progress frames.'
        });
      }

      if (speedline.speedIndex === 0) {
        return SpeedIndexMetric.generateAuditResult({
          rawValue: -1,
          debugString: 'Error in Speedline calculating Speed Index (speedIndex of 0).'
        });
      }

      // Use the CDF of a log-normal distribution for scoring.
      //  10th Percentile = 2,240
      //  25th Percentile = 3,430
      //  Median = 5,500
      //  75th Percentile = 8,820
      //  95th Percentile = 17,400
      const distribution = TracingProcessor.getLogNormalDistribution(SCORING_MEDIAN,
        SCORING_POINT_OF_DIMINISHING_RETURNS);
      let score = 100 * distribution.computeComplementaryPercentile(speedline.perceptualSpeedIndex);

      // Clamp the score to 0 <= x <= 100.
      score = Math.min(100, score);
      score = Math.max(0, score);

      const extendedInfo = {
        first: speedline.first,
        complete: speedline.complete,
        duration: speedline.duration,
        frames: speedline.frames.map(frame => {
          return {
            timestamp: frame.getTimeStamp(),
            progress: frame.getPerceptualProgress()
          };
        })
      };

      return SpeedIndexMetric.generateAuditResult({
        score: Math.round(score),
        rawValue: Math.round(speedline.perceptualSpeedIndex),
        optimalValue: this.meta.optimalValue,
        extendedInfo: {
          formatter: Formatter.SUPPORTED_FORMATS.SPEEDLINE,
          value: extendedInfo
        }
      });
    }).catch(err => {
      return SpeedIndexMetric.generateAuditResult({
        rawValue: -1,
        debugString: err.message
      });
    });
  }
}

module.exports = SpeedIndexMetric;
