"use strict";
/**
Copyright 2016 The Chromium Authors. All rights reserved.
Use of this source code is governed by a BSD-style license that can be
found in the LICENSE file.
**/

var _slicedToArray = function () { function sliceIterator(arr, i) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"]) _i["return"](); } finally { if (_d) throw _e; } } return _arr; } return function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { return sliceIterator(arr, i); } else { throw new TypeError("Invalid attempt to destructure non-iterable instance"); } }; }();

require("../../model/event_set.js");
require("./diagnostic.js");
require("./event_ref.js");

'use strict';

global.tr.exportTo('tr.v.d', function () {
  /**
   * @typedef {!(tr.v.d.EventRef|tr.model.Event)} EventLike
   */

  /**
   * A RelatedEventSet diagnostic contains references to Events
   */
  class RelatedEventSet extends tr.v.d.Diagnostic {
    /**
     * @param {!(tr.model.EventSet|Array.<EventLike>|EventLike)=} opt_events
     */
    constructor(opt_events) {
      super();
      this.eventsByStableId_ = new Map();
      if (opt_events) {
        if (opt_events instanceof tr.model.EventSet || opt_events instanceof Array) {
          for (var event of opt_events) this.add(event);
        } else {
          this.add(opt_events);
        }
      }
    }

    /**
     * @param {!(tr.v.d.EventRef|tr.model.Event)} event
     */
    add(event) {
      this.eventsByStableId_.set(event.stableId, event);
    }

    /**
     * @param {!(tr.v.d.EventRef|tr.model.Event)} event
     * @return {boolean}
     */
    has(event) {
      return this.eventsByStableId_.has(event.stableId);
    }

    get length() {
      return this.eventsByStableId_.size;
    }

    *[Symbol.iterator]() {
      for (var _ref of this.eventsByStableId_) {
        var _ref2 = _slicedToArray(_ref, 2);

        var stableId = _ref2[0];
        var event = _ref2[1];

        yield event;
      }
    }

    /**
     * Resolve all EventRefs into Events by finding their stableIds in |model|.
     * If a stableId cannot be found and |opt_required| is true, then throw an
     * Error.
     * If a stableId cannot be found and |opt_required| is false, then the
     * EventRef will remain an EventRef.
     *
     * @param {!tr.model.Model} model
     * @param {boolean=} opt_required
     */
    resolve(model, opt_required) {
      for (var _ref3 of this.eventsByStableId_) {
        var _ref4 = _slicedToArray(_ref3, 2);

        var stableId = _ref4[0];
        var event = _ref4[1];

        if (!(event instanceof tr.v.d.EventRef)) continue;

        event = model.getEventByStableId(stableId);
        if (event instanceof tr.model.Event) this.eventsByStableId_.set(stableId, event);else if (opt_required) throw new Error('Unable to find Event ' + stableId);
      }
    }

    asDictInto_(d) {
      d.events = [];
      for (var event of this) {
        d.events.push({
          stableId: event.stableId,
          title: event.title,
          start: event.start,
          duration: event.duration
        });
      }
    }

    static fromDict(d) {
      return new RelatedEventSet(d.events.map(event => new tr.v.d.EventRef(event)));
    }
  }

  tr.v.d.Diagnostic.register(RelatedEventSet, {
    elementName: 'tr-v-ui-related-event-set-span'
  });

  return {
    RelatedEventSet: RelatedEventSet
  };
});