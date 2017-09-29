"use strict";
/**
Copyright (c) 2016 The Chromium Authors. All rights reserved.
Use of this source code is governed by a BSD-style license that can be
found in the LICENSE file.
**/

require("../base/unit.js");

'use strict';

global.tr.exportTo('tr.model', function () {

  /**
   * @constructor
   */
  function ModelStats() {
    this.traceEventCountsByKey_ = new Map();
    this.allTraceEventStats_ = [];

    this.traceEventStatsInTimeIntervals_ = new Map();
    this.allTraceEventStatsInTimeIntervals_ = [];

    this.hasEventSizesinBytes_ = false;
  }

  ModelStats.prototype = {
    TIME_INTERVAL_SIZE_IN_MS: 100,

    willProcessBasicTraceEvent: function (phase, category, title, ts, opt_eventSizeinBytes) {
      var key = phase + '/' + category + '/' + title;
      var eventStats = this.traceEventCountsByKey_.get(key);
      if (eventStats === undefined) {
        eventStats = {
          phase: phase,
          category: category,
          title: title,
          numEvents: 0,
          totalEventSizeinBytes: 0
        };
        this.traceEventCountsByKey_.set(key, eventStats);
        this.allTraceEventStats_.push(eventStats);
      }
      eventStats.numEvents++;

      var timeIntervalKey = Math.floor(tr.b.Unit.timestampFromUs(ts) / this.TIME_INTERVAL_SIZE_IN_MS);
      var eventStatsByTimeInverval = this.traceEventStatsInTimeIntervals_.get(timeIntervalKey);
      if (eventStatsByTimeInverval === undefined) {
        eventStatsByTimeInverval = {
          timeInterval: timeIntervalKey,
          numEvents: 0,
          totalEventSizeinBytes: 0
        };
        this.traceEventStatsInTimeIntervals_.set(timeIntervalKey, eventStatsByTimeInverval);
        this.allTraceEventStatsInTimeIntervals_.push(eventStatsByTimeInverval);
      }
      eventStatsByTimeInverval.numEvents++;

      if (opt_eventSizeinBytes !== undefined) {
        this.hasEventSizesinBytes_ = true;
        eventStats.totalEventSizeinBytes += opt_eventSizeinBytes;
        eventStatsByTimeInverval.totalEventSizeinBytes += opt_eventSizeinBytes;
      }
    },

    get allTraceEventStats() {
      return this.allTraceEventStats_;
    },

    get allTraceEventStatsInTimeIntervals() {
      return this.allTraceEventStatsInTimeIntervals_;
    },

    get hasEventSizesinBytes() {
      return this.hasEventSizesinBytes_;
    }
  };

  return {
    ModelStats: ModelStats
  };
});