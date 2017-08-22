"use strict";
/**
Copyright 2016 The Chromium Authors. All rights reserved.
Use of this source code is governed by a BSD-style license that can be
found in the LICENSE file.
**/

var _slicedToArray = function () { function sliceIterator(arr, i) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"]) _i["return"](); } finally { if (_d) throw _e; } } return _arr; } return function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { return sliceIterator(arr, i); } else { throw new TypeError("Invalid attempt to destructure non-iterable instance"); } }; }();

require("../../base/iteration_helpers.js");
require("./diagnostic.js");
require("./value_ref.js");

'use strict';

global.tr.exportTo('tr.v.d', function () {
  class RelatedValueSet extends tr.v.d.Diagnostic {
    constructor(opt_values) {
      super();
      this.valuesByGuid_ = new Map();

      if (opt_values) for (var value of opt_values) this.add(value);
    }

    /**
     * @param {!(tr.v.d.ValueRef|tr.v.Histogram)} v
     */
    add(value) {
      if (!(value instanceof tr.v.Histogram) && !(value instanceof tr.v.d.ValueRef)) throw new Error('Must be instanceof Histogram or ValueRef: ' + value);

      if (this.valuesByGuid_.get(value.guid)) throw new Error('Tried to add same value twice');

      this.valuesByGuid_.set(value.guid, value);
    }

    has(value) {
      return this.valuesByGuid_.has(value.guid);
    }

    get length() {
      return this.valuesByGuid_.size;
    }

    *[Symbol.iterator]() {
      for (var _ref of this.valuesByGuid_) {
        var _ref2 = _slicedToArray(_ref, 2);

        var guid = _ref2[0];
        var value = _ref2[1];

        yield value;
      }
    }

    /**
     * Resolve all ValueRefs into Values by looking up their guids in
     * |valueSet|.
     * If a value cannot be found and |opt_required| is true, then throw an
     * Error.
     * If a value cannot be found and |opt_required| is false, then the ValueRef
     * will remain a ValueRef.
     *
     * @param {!tr.v.ValueSet} valueSet
     * @param {boolean=} opt_required
     */
    resolve(valueSet, opt_required) {
      for (var _ref3 of this.valuesByGuid_) {
        var _ref4 = _slicedToArray(_ref3, 2);

        var guid = _ref4[0];
        var value = _ref4[1];

        if (!(value instanceof tr.v.d.ValueRef)) continue;

        value = valueSet.lookup(guid);
        if (value instanceof tr.v.Histogram) this.valuesByGuid_.set(guid, value);else if (opt_required) throw new Error('Unable to find Histogram ' + guid);
      }
    }

    asDictInto_(d) {
      d.guids = [];
      for (var value of this) d.guids.push(value.guid);
    }

    static fromDict(d) {
      return new RelatedValueSet(d.guids.map(guid => new tr.v.d.ValueRef(guid)));
    }
  }

  tr.v.d.Diagnostic.register(RelatedValueSet, {
    elementName: 'tr-v-ui-related-value-set-span'
  });

  return {
    RelatedValueSet: RelatedValueSet
  };
});