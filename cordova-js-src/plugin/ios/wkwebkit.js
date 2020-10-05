/*
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *
*/

var exec = require('cordova/exec');

var WkWebKit = {
    allowsBackForwardNavigationGestures: function (allow) {
        exec(null, null, 'CDVWebViewEngine', 'allowsBackForwardNavigationGestures', [allow]);
    },
    convertFilePath: function (path) {
        if (!path || !window.CDV_ASSETS_URL) {
            return path;
        }
        if (path.startsWith('/')) {
            return window.CDV_ASSETS_URL + '/_app_file_' + path;
        }
        if (path.startsWith('file://')) {
            return window.CDV_ASSETS_URL + path.replace('file://', '/_app_file_');
        }
        if (path.startsWith('http://')) {
            return window.CDV_ASSETS_URL + '/_http_proxy_' + encodeURIComponent(path.replace('http://', ''));
        }
        if (path.startsWith('https://')) {
            return window.CDV_ASSETS_URL + '/_https_proxy_' + encodeURIComponent(path.replace('https://', ''));
        }
        return path;
    }
};

module.exports = WkWebKit;
