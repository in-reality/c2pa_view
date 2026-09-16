var wasm_bindgen = (function(exports) {
    let script_src;
    if (typeof document !== 'undefined' && document.currentScript !== null) {
        script_src = new URL(document.currentScript.src, location.href).toString();
    }

    class WorkerPool {
        static __wrap(ptr) {
            const obj = Object.create(WorkerPool.prototype);
            obj.__wbg_ptr = ptr;
            WorkerPoolFinalization.register(obj, obj.__wbg_ptr, obj);
            return obj;
        }
        __destroy_into_raw() {
            const ptr = this.__wbg_ptr;
            this.__wbg_ptr = 0;
            WorkerPoolFinalization.unregister(this);
            return ptr;
        }
        free() {
            const ptr = this.__destroy_into_raw();
            wasm.__wbg_workerpool_free(ptr, 0);
        }
        /**
         * @param {number | null} [initial]
         * @param {string | null} [script_src]
         * @param {string | null} [worker_js_preamble]
         * @param {string | null} [wasm_bindgen_name]
         * @returns {WorkerPool}
         */
        static new(initial, script_src, worker_js_preamble, wasm_bindgen_name) {
            var ptr0 = isLikeNone(script_src) ? 0 : passStringToWasm0(script_src, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            var len0 = WASM_VECTOR_LEN;
            var ptr1 = isLikeNone(worker_js_preamble) ? 0 : passStringToWasm0(worker_js_preamble, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            var len1 = WASM_VECTOR_LEN;
            var ptr2 = isLikeNone(wasm_bindgen_name) ? 0 : passStringToWasm0(wasm_bindgen_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            var len2 = WASM_VECTOR_LEN;
            const ret = wasm.workerpool_new(isLikeNone(initial) ? Number.MAX_SAFE_INTEGER : (initial) >>> 0, ptr0, len0, ptr1, len1, ptr2, len2);
            if (ret[2]) {
                throw takeFromExternrefTable0(ret[1]);
            }
            return WorkerPool.__wrap(ret[0]);
        }
        /**
         * Creates a new `WorkerPool` which immediately creates `initial` workers.
         *
         * The pool created here can be used over a long period of time, and it
         * will be initially primed with `initial` workers. Currently workers are
         * never released or gc'd until the whole pool is destroyed.
         *
         * # Errors
         *
         * Returns any error that may happen while a JS web worker is created and a
         * message is sent to it.
         * @param {number} initial
         * @param {string} script_src
         * @param {string} worker_js_preamble
         * @param {string} wasm_bindgen_name
         */
        constructor(initial, script_src, worker_js_preamble, wasm_bindgen_name) {
            const ptr0 = passStringToWasm0(script_src, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            const len0 = WASM_VECTOR_LEN;
            const ptr1 = passStringToWasm0(worker_js_preamble, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            const len1 = WASM_VECTOR_LEN;
            const ptr2 = passStringToWasm0(wasm_bindgen_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            const len2 = WASM_VECTOR_LEN;
            const ret = wasm.workerpool_new_raw(initial, ptr0, len0, ptr1, len1, ptr2, len2);
            if (ret[2]) {
                throw takeFromExternrefTable0(ret[1]);
            }
            this.__wbg_ptr = ret[0];
            WorkerPoolFinalization.register(this, this.__wbg_ptr, this);
            return this;
        }
    }
    if (Symbol.dispose) WorkerPool.prototype[Symbol.dispose] = WorkerPool.prototype.free;
    exports.WorkerPool = WorkerPool;

    /**
     * @param {number} call_id
     * @param {any} ptr_
     * @param {number} rust_vec_len_
     * @param {number} data_len_
     */
    function frb_dart_fn_deliver_output(call_id, ptr_, rust_vec_len_, data_len_) {
        wasm.frb_dart_fn_deliver_output(call_id, ptr_, rust_vec_len_, data_len_);
    }
    exports.frb_dart_fn_deliver_output = frb_dart_fn_deliver_output;

    /**
     * # Safety
     *
     * This should never be called manually.
     * @param {any} handle
     * @param {any} dart_handler_port
     * @returns {number}
     */
    function frb_dart_opaque_dart2rust_encode(handle, dart_handler_port) {
        const ret = wasm.frb_dart_opaque_dart2rust_encode(handle, dart_handler_port);
        return ret >>> 0;
    }
    exports.frb_dart_opaque_dart2rust_encode = frb_dart_opaque_dart2rust_encode;

    /**
     * @param {number} ptr
     */
    function frb_dart_opaque_drop_thread_box_persistent_handle(ptr) {
        wasm.frb_dart_opaque_drop_thread_box_persistent_handle(ptr);
    }
    exports.frb_dart_opaque_drop_thread_box_persistent_handle = frb_dart_opaque_drop_thread_box_persistent_handle;

    /**
     * @param {number} ptr
     * @returns {any}
     */
    function frb_dart_opaque_rust2dart_decode(ptr) {
        const ret = wasm.frb_dart_opaque_rust2dart_decode(ptr);
        return ret;
    }
    exports.frb_dart_opaque_rust2dart_decode = frb_dart_opaque_rust2dart_decode;

    /**
     * @returns {number}
     */
    function frb_get_rust_content_hash() {
        const ret = wasm.frb_get_rust_content_hash();
        return ret;
    }
    exports.frb_get_rust_content_hash = frb_get_rust_content_hash;

    /**
     * @param {number} func_id
     * @param {any} port_
     * @param {any} ptr_
     * @param {number} rust_vec_len_
     * @param {number} data_len_
     */
    function frb_pde_ffi_dispatcher_primary(func_id, port_, ptr_, rust_vec_len_, data_len_) {
        wasm.frb_pde_ffi_dispatcher_primary(func_id, port_, ptr_, rust_vec_len_, data_len_);
    }
    exports.frb_pde_ffi_dispatcher_primary = frb_pde_ffi_dispatcher_primary;

    /**
     * @param {number} func_id
     * @param {any} ptr_
     * @param {number} rust_vec_len_
     * @param {number} data_len_
     * @returns {any}
     */
    function frb_pde_ffi_dispatcher_sync(func_id, ptr_, rust_vec_len_, data_len_) {
        const ret = wasm.frb_pde_ffi_dispatcher_sync(func_id, ptr_, rust_vec_len_, data_len_);
        return ret;
    }
    exports.frb_pde_ffi_dispatcher_sync = frb_pde_ffi_dispatcher_sync;

    /**
     * ## Safety
     * This function reclaims a raw pointer created by [`TransferClosure`], and therefore
     * should **only** be used in conjunction with it.
     * Furthermore, the WASM module in the worker must have been initialized with the shared
     * memory from the host JS scope.
     * @param {number} payload
     * @param {any[]} transfer
     */
    function receive_transfer_closure(payload, transfer) {
        const ptr0 = passArrayJsValueToWasm0(transfer, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.receive_transfer_closure(payload, ptr0, len0);
        if (ret[1]) {
            throw takeFromExternrefTable0(ret[0]);
        }
    }
    exports.receive_transfer_closure = receive_transfer_closure;

    function wasm_start_callback() {
        wasm.wasm_start_callback();
    }
    exports.wasm_start_callback = wasm_start_callback;
    function __wbg_get_imports() {
        const import0 = {
            __proto__: null,
            __wbg___wbindgen_debug_string_0e68cf47c9cbd9b0: function(arg0, arg1) {
                const ret = debugString(arg1);
                const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
                const len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            },
            __wbg___wbindgen_is_function_fcda5e3902d732fe: function(arg0) {
                const ret = typeof(arg0) === 'function';
                return ret;
            },
            __wbg___wbindgen_is_undefined_8c687d0b90d5b524: function(arg0) {
                const ret = arg0 === undefined;
                return ret;
            },
            __wbg___wbindgen_jsval_eq_9fdcd3c0a860dd3b: function(arg0, arg1) {
                const ret = arg0 === arg1;
                return ret;
            },
            __wbg___wbindgen_memory_3f8442e22540244f: function() {
                const ret = wasm.memory;
                return ret;
            },
            __wbg___wbindgen_module_c2aeeb3b14bad631: function() {
                const ret = wasmModule;
                return ret;
            },
            __wbg___wbindgen_number_get_1dc732b810cb937c: function(arg0, arg1) {
                const obj = arg1;
                const ret = typeof(obj) === 'number' ? obj : undefined;
                getDataViewMemory0().setFloat64(arg0 + 8 * 1, isLikeNone(ret) ? 0 : ret, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, !isLikeNone(ret), true);
            },
            __wbg___wbindgen_string_get_92ab86bb19cbc12f: function(arg0, arg1) {
                const obj = arg1;
                const ret = typeof(obj) === 'string' ? obj : undefined;
                var ptr1 = isLikeNone(ret) ? 0 : passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
                var len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            },
            __wbg___wbindgen_throw_5d9e815e6fdf150f: function(arg0, arg1) {
                throw new Error(getStringFromWasm0(arg0, arg1));
            },
            __wbg__wbg_cb_unref_997e73d32238e655: function(arg0) {
                arg0._wbg_cb_unref();
            },
            __wbg_createObjectURL_7dadebfd232e594a: function() { return handleError(function (arg0, arg1) {
                const ret = URL.createObjectURL(arg1);
                const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
                const len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            }, arguments); },
            __wbg_data_aa7ba49b34c0d883: function(arg0) {
                const ret = arg0.data;
                return ret;
            },
            __wbg_error_757e9472f8410341: function(arg0, arg1) {
                let deferred0_0;
                let deferred0_1;
                try {
                    deferred0_0 = arg0;
                    deferred0_1 = arg1;
                    console.error(getStringFromWasm0(arg0, arg1));
                } finally {
                    wasm.__wbindgen_free(deferred0_0, deferred0_1, 1);
                }
            },
            __wbg_error_7f1d438faea3480f: function(arg0, arg1) {
                console.error(getStringFromWasm0(arg0, arg1));
            },
            __wbg_eval_7759a61726fa9c38: function() { return handleError(function (arg0, arg1) {
                const ret = eval(getStringFromWasm0(arg0, arg1));
                return ret;
            }, arguments); },
            __wbg_getTime_65922ba0b59d55a7: function(arg0) {
                const ret = arg0.getTime();
                return ret;
            },
            __wbg_get_989d0a1309644f2b: function() { return handleError(function (arg0, arg1) {
                const ret = Reflect.get(arg0, arg1);
                return ret;
            }, arguments); },
            __wbg_instanceof_BroadcastChannel_5db2d2786a7b5dcb: function(arg0) {
                let result;
                try {
                    result = arg0 instanceof BroadcastChannel;
                } catch (_) {
                    result = false;
                }
                const ret = result;
                return ret;
            },
            __wbg_instanceof_ErrorEvent_7c9f5160f3a47d83: function(arg0) {
                let result;
                try {
                    result = arg0 instanceof ErrorEvent;
                } catch (_) {
                    result = false;
                }
                const ret = result;
                return ret;
            },
            __wbg_instanceof_MessageEvent_feafc259c6e9c5f1: function(arg0) {
                let result;
                try {
                    result = arg0 instanceof MessageEvent;
                } catch (_) {
                    result = false;
                }
                const ret = result;
                return ret;
            },
            __wbg_length_31bdaf014f5fbde2: function(arg0) {
                const ret = arg0.length;
                return ret;
            },
            __wbg_message_247942253a4ea78c: function(arg0, arg1) {
                const ret = arg1.message;
                const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
                const len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            },
            __wbg_name_93e3e3f1e2c52cd1: function(arg0, arg1) {
                const ret = arg1.name;
                const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
                const len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            },
            __wbg_new_0_35540e542ba689d2: function() {
                const ret = new Date();
                return ret;
            },
            __wbg_new_1da3429bc3c4541c: function(arg0) {
                const ret = new Uint8Array(arg0);
                return ret;
            },
            __wbg_new_227d7c05414eb861: function() {
                const ret = new Error();
                return ret;
            },
            __wbg_new_4971674b3561f783: function() { return handleError(function (arg0, arg1) {
                const ret = new BroadcastChannel(getStringFromWasm0(arg0, arg1));
                return ret;
            }, arguments); },
            __wbg_new_a313bf260f9bdcc3: function() { return handleError(function (arg0, arg1) {
                const ret = new Worker(getStringFromWasm0(arg0, arg1));
                return ret;
            }, arguments); },
            __wbg_new_bebc3f4757acf305: function() {
                const ret = new Object();
                return ret;
            },
            __wbg_new_ffa92086ea89f79c: function() {
                const ret = new Array();
                return ret;
            },
            __wbg_new_from_slice_4ee02165f9de919e: function(arg0, arg1) {
                const ret = new Uint8Array(getArrayU8FromWasm0(arg0, arg1));
                return ret;
            },
            __wbg_new_with_blob_sequence_and_options_5a90e65879b0ae98: function() { return handleError(function (arg0, arg1) {
                const ret = new Blob(arg0, arg1);
                return ret;
            }, arguments); },
            __wbg_now_d1fb6650485d7f3e: function() {
                const ret = Date.now();
                return ret;
            },
            __wbg_postMessage_14c07434f6b7e150: function() { return handleError(function (arg0, arg1) {
                arg0.postMessage(arg1);
            }, arguments); },
            __wbg_postMessage_1f51e50254674143: function() { return handleError(function (arg0, arg1) {
                arg0.postMessage(arg1);
            }, arguments); },
            __wbg_postMessage_59736484efc322cf: function() { return handleError(function (arg0, arg1) {
                arg0.postMessage(arg1);
            }, arguments); },
            __wbg_prototypesetcall_ae9f5e7459250748: function(arg0, arg1, arg2) {
                Uint8Array.prototype.set.call(getArrayU8FromWasm0(arg0, arg1), arg2);
            },
            __wbg_push_bfdf956ba476f65b: function(arg0, arg1) {
                const ret = arg0.push(arg1);
                return ret;
            },
            __wbg_queueMicrotask_85c90f6987555d65: function(arg0) {
                const ret = arg0.queueMicrotask;
                return ret;
            },
            __wbg_queueMicrotask_f6a1fa10b81d1fc0: function(arg0) {
                queueMicrotask(arg0);
            },
            __wbg_resolve_35ec7e0c6af4c82c: function(arg0) {
                const ret = Promise.resolve(arg0);
                return ret;
            },
            __wbg_set_a377297433dfea63: function() { return handleError(function (arg0, arg1, arg2) {
                const ret = Reflect.set(arg0, arg1, arg2);
                return ret;
            }, arguments); },
            __wbg_set_onerror_30dd5b507c57e96f: function(arg0, arg1) {
                arg0.onerror = arg1;
            },
            __wbg_set_onmessage_d7e69fe35723df1e: function(arg0, arg1) {
                arg0.onmessage = arg1;
            },
            __wbg_set_type_69954a3c7c11a724: function(arg0, arg1, arg2) {
                arg0.type = getStringFromWasm0(arg1, arg2);
            },
            __wbg_stack_3b0d974bbf31e44f: function(arg0, arg1) {
                const ret = arg1.stack;
                const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
                const len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            },
            __wbg_static_accessor_GLOBAL_8eb4cd83130a11a0: function() {
                const ret = typeof global === 'undefined' ? null : global;
                return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
            },
            __wbg_static_accessor_GLOBAL_THIS_1e7044f654e934db: function() {
                const ret = typeof globalThis === 'undefined' ? null : globalThis;
                return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
            },
            __wbg_static_accessor_SELF_d8b50611246a6d92: function() {
                const ret = typeof self === 'undefined' ? null : self;
                return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
            },
            __wbg_static_accessor_WINDOW_fd0bc376bf0f8b42: function() {
                const ret = typeof window === 'undefined' ? null : window;
                return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
            },
            __wbg_then_b830475380919203: function(arg0, arg1) {
                const ret = arg0.then(arg1);
                return ret;
            },
            __wbindgen_generic_0000000000000001: function(arg0, arg1) {
                // Cast intrinsic for `Closure(Closure { owned: true, function: Function { arguments: [Externref], shim_idx: 1790, ret: Result(Unit), inner_ret: Some(Result(Unit)) }, mutable: true }) -> Externref`.
                const ret = makeMutClosure(arg0, arg1, wasm_bindgen__convert__closures_____invoke__h80339b5f8cd30c37);
                return ret;
            },
            __wbindgen_generic_0000000000000002: function(arg0, arg1) {
                // Cast intrinsic for `Closure(Closure { owned: true, function: Function { arguments: [NamedExternref("Event")], shim_idx: 157, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
                const ret = makeMutClosure(arg0, arg1, wasm_bindgen__convert__closures_____invoke__h6f4c18ca6ccdd941);
                return ret;
            },
            __wbindgen_generic_0000000000000003: function(arg0) {
                // Cast intrinsic for `F64 -> Externref`.
                const ret = arg0;
                return ret;
            },
            __wbindgen_generic_0000000000000004: function(arg0, arg1) {
                // Cast intrinsic for `Ref(String) -> Externref`.
                const ret = getStringFromWasm0(arg0, arg1);
                return ret;
            },
            __wbindgen_init_externref_table: function() {
                const table = wasm.__wbindgen_externrefs;
                const offset = table.grow(4);
                table.set(0, undefined);
                table.set(offset + 0, undefined);
                table.set(offset + 1, null);
                table.set(offset + 2, true);
                table.set(offset + 3, false);
            },
        };
        return {
            __proto__: null,
            "./c2pa_view_bg.js": import0,
        };
    }

    function wasm_bindgen__convert__closures_____invoke__h6f4c18ca6ccdd941(arg0, arg1, arg2) {
        wasm.wasm_bindgen__convert__closures_____invoke__h6f4c18ca6ccdd941(arg0, arg1, arg2);
    }

    function wasm_bindgen__convert__closures_____invoke__h80339b5f8cd30c37(arg0, arg1, arg2) {
        const ret = wasm.wasm_bindgen__convert__closures_____invoke__h80339b5f8cd30c37(arg0, arg1, arg2);
        if (ret[1]) {
            throw takeFromExternrefTable0(ret[0]);
        }
    }

    const WorkerPoolFinalization = (typeof FinalizationRegistry === 'undefined')
        ? { register: () => {}, unregister: () => {} }
        : new FinalizationRegistry(ptr => wasm.__wbg_workerpool_free(ptr, 1));

    function addToExternrefTable0(obj) {
        const idx = wasm.__externref_table_alloc();
        wasm.__wbindgen_externrefs.set(idx, obj);
        return idx;
    }

    const CLOSURE_DTORS = (typeof FinalizationRegistry === 'undefined')
        ? { register: () => {}, unregister: () => {} }
        : new FinalizationRegistry(state => wasm.__wbindgen_destroy_closure(state.a, state.b));

    function debugString(val) {
        // primitive types
        const type = typeof val;
        if (type == 'number' || type == 'boolean' || val == null) {
            return  `${val}`;
        }
        if (type == 'string') {
            return `"${val}"`;
        }
        if (type == 'symbol') {
            const description = val.description;
            if (description == null) {
                return 'Symbol';
            } else {
                return `Symbol(${description})`;
            }
        }
        if (type == 'function') {
            const name = val.name;
            if (typeof name == 'string' && name.length > 0) {
                return `Function(${name})`;
            } else {
                return 'Function';
            }
        }
        // objects
        if (Array.isArray(val)) {
            const length = val.length;
            let debug = '[';
            if (length > 0) {
                debug += debugString(val[0]);
            }
            for(let i = 1; i < length; i++) {
                debug += ', ' + debugString(val[i]);
            }
            debug += ']';
            return debug;
        }
        // Test for built-in
        const builtInMatches = /\[object ([^\]]+)\]/.exec(toString.call(val));
        let className;
        if (builtInMatches && builtInMatches.length > 1) {
            className = builtInMatches[1];
        } else {
            // Failed to match the standard '[object ClassName]'
            return toString.call(val);
        }
        if (className == 'Object') {
            // we're a user defined class or Object
            // JSON.stringify avoids problems with cycles, and is generally much
            // easier than looping through ownProperties of `val`.
            try {
                return 'Object(' + JSON.stringify(val) + ')';
            } catch (_) {
                return 'Object';
            }
        }
        // errors
        if (val instanceof Error) {
            return `${val.name}: ${val.message}\n${val.stack}`;
        }
        // TODO we could test for more things here, like `Set`s and `Map`s.
        return className;
    }

    function getArrayU8FromWasm0(ptr, len) {
        ptr = ptr >>> 0;
        return getUint8ArrayMemory0().subarray(ptr / 1, ptr / 1 + len);
    }

    let cachedDataViewMemory0 = null;
    function getDataViewMemory0() {
        if (cachedDataViewMemory0 === null || cachedDataViewMemory0.buffer.detached === true || (cachedDataViewMemory0.buffer.detached === undefined && cachedDataViewMemory0.buffer !== wasm.memory.buffer)) {
            cachedDataViewMemory0 = new DataView(wasm.memory.buffer);
        }
        return cachedDataViewMemory0;
    }

    function getStringFromWasm0(ptr, len) {
        return decodeText(ptr >>> 0, len);
    }

    let cachedUint8ArrayMemory0 = null;
    function getUint8ArrayMemory0() {
        if (cachedUint8ArrayMemory0 === null || cachedUint8ArrayMemory0.byteLength === 0) {
            cachedUint8ArrayMemory0 = new Uint8Array(wasm.memory.buffer);
        }
        return cachedUint8ArrayMemory0;
    }

    function handleError(f, args) {
        try {
            return f.apply(this, args);
        } catch (e) {
            const idx = addToExternrefTable0(e);
            wasm.__wbindgen_exn_store(idx);
        }
    }

    function isLikeNone(x) {
        return x === undefined || x === null;
    }

    function makeMutClosure(arg0, arg1, f) {
        const state = { a: arg0, b: arg1, cnt: 1 };
        const real = (...args) => {

            // First up with a closure we increment the internal reference
            // count. This ensures that the Rust closure environment won't
            // be deallocated while we're invoking it.
            state.cnt++;
            const a = state.a;
            state.a = 0;
            try {
                return f(a, state.b, ...args);
            } finally {
                state.a = a;
                real._wbg_cb_unref();
            }
        };
        real._wbg_cb_unref = () => {
            if (--state.cnt === 0) {
                wasm.__wbindgen_destroy_closure(state.a, state.b);
                state.a = 0;
                CLOSURE_DTORS.unregister(state);
            }
        };
        CLOSURE_DTORS.register(real, state, state);
        return real;
    }

    function passArrayJsValueToWasm0(array, malloc) {
        const ptr = malloc(array.length * 4, 4) >>> 0;
        for (let i = 0; i < array.length; i++) {
            const add = addToExternrefTable0(array[i]);
            getDataViewMemory0().setUint32(ptr + 4 * i, add, true);
        }
        WASM_VECTOR_LEN = array.length;
        return ptr;
    }

    function passStringToWasm0(arg, malloc, realloc) {
        if (realloc === undefined) {
            const buf = cachedTextEncoder.encode(arg);
            const ptr = malloc(buf.length, 1) >>> 0;
            getUint8ArrayMemory0().subarray(ptr, ptr + buf.length).set(buf);
            WASM_VECTOR_LEN = buf.length;
            return ptr;
        }

        let len = arg.length;
        let ptr = malloc(len, 1) >>> 0;

        const mem = getUint8ArrayMemory0();

        let offset = 0;

        for (; offset < len; offset++) {
            const code = arg.charCodeAt(offset);
            if (code > 0x7F) break;
            mem[ptr + offset] = code;
        }
        if (offset !== len) {
            if (offset !== 0) {
                arg = arg.slice(offset);
            }
            ptr = realloc(ptr, len, len = offset + arg.length * 3, 1) >>> 0;
            const view = getUint8ArrayMemory0().subarray(ptr + offset, ptr + len);
            const ret = cachedTextEncoder.encodeInto(arg, view);

            offset += ret.written;
            ptr = realloc(ptr, len, offset, 1) >>> 0;
        }

        WASM_VECTOR_LEN = offset;
        return ptr;
    }

    function takeFromExternrefTable0(idx) {
        const value = wasm.__wbindgen_externrefs.get(idx);
        wasm.__externref_table_dealloc(idx);
        return value;
    }

    let cachedTextDecoder = new TextDecoder('utf-8', { ignoreBOM: true, fatal: true });
    cachedTextDecoder.decode();
    function decodeText(ptr, len) {
        return cachedTextDecoder.decode(getUint8ArrayMemory0().subarray(ptr, ptr + len));
    }

    const cachedTextEncoder = new TextEncoder();

    if (!('encodeInto' in cachedTextEncoder)) {
        cachedTextEncoder.encodeInto = function (arg, view) {
            const buf = cachedTextEncoder.encode(arg);
            view.set(buf);
            return {
                read: arg.length,
                written: buf.length
            };
        };
    }

    let WASM_VECTOR_LEN = 0;

    let wasmModule, wasmInstance, wasm;
    function __wbg_finalize_init(instance, module) {
        wasmInstance = instance;
        wasm = instance.exports;
        wasmModule = module;
        cachedDataViewMemory0 = null;
        cachedUint8ArrayMemory0 = null;
        wasm.__wbindgen_start();
        return wasm;
    }

    async function __wbg_load(module, imports) {
        if (typeof Response === 'function' && module instanceof Response) {
            if (!module.ok) {
                throw new Error(`failed to fetch Wasm: ${module.status} ${module.statusText} fetching '${module.url}'`);
            }

            if (typeof WebAssembly.instantiateStreaming === 'function') {
                try {
                    return await WebAssembly.instantiateStreaming(module, imports);
                } catch (e) {
                    const validResponse = expectedResponseType(module.type);

                    if (validResponse && module.headers.get('Content-Type') !== 'application/wasm') {
                        console.warn("`WebAssembly.instantiateStreaming` failed because your server does not serve Wasm with `application/wasm` MIME type. Falling back to `WebAssembly.instantiate` which is slower. Original error:\n", e);

                    } else { throw e; }
                }
            }

            const bytes = await module.arrayBuffer();
            return await WebAssembly.instantiate(bytes, imports);
        } else {
            const instance = await WebAssembly.instantiate(module, imports);

            if (instance instanceof WebAssembly.Instance) {
                return { instance, module };
            } else {
                return instance;
            }
        }

        function expectedResponseType(type) {
            switch (type) {
                case 'basic': case 'cors': case 'default': return true;
            }
            return false;
        }
    }

    function initSync(module) {
        if (wasm !== undefined) return wasm;


        if (module !== undefined) {
            if (Object.getPrototypeOf(module) === Object.prototype) {
                ({module} = module)
            } else {
                console.warn('using deprecated parameters for `initSync()`; pass a single object instead')
            }
        }

        const imports = __wbg_get_imports();
        if (!(module instanceof WebAssembly.Module)) {
            module = new WebAssembly.Module(module);
        }
        const instance = new WebAssembly.Instance(module, imports);
        return __wbg_finalize_init(instance, module);
    }

    async function __wbg_init(module_or_path) {
        if (wasm !== undefined) return wasm;


        if (module_or_path !== undefined) {
            if (Object.getPrototypeOf(module_or_path) === Object.prototype) {
                ({module_or_path} = module_or_path)
            } else {
                console.warn('using deprecated parameters for the initialization function; pass a single object instead')
            }
        }

        if (module_or_path === undefined && script_src !== undefined) {
            module_or_path = script_src.replace(/\.js$/, "_bg.wasm");
        }
        const imports = __wbg_get_imports();

        if (typeof module_or_path === 'string' || (typeof Request === 'function' && module_or_path instanceof Request) || (typeof URL === 'function' && module_or_path instanceof URL)) {
            module_or_path = fetch(module_or_path);
        }

        const { instance, module } = await __wbg_load(await module_or_path, imports);

        return __wbg_finalize_init(instance, module);
    }

    return Object.assign(__wbg_init, { initSync }, exports);
})({ __proto__: null });
