#include <Python.h>
#include <datetime.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

// Forward declarations
PyObject* PyInit_python3(void);
typedef struct {
    PyObject *(*call_raku_object)(int, PyObject *, PyObject **);
    PyObject *(*call_raku_method)(int, char *, PyObject *, PyObject **);
} RakuCallbacks;

static RakuCallbacks raku_callbacks;

// Error handling
typedef struct {
    PyObject *type;
    PyObject *value;
    PyObject *traceback;
    char *formatted_exception;
} PythonError;

// Initialize Python interpreter with better error handling
int python3_init_python(RakuCallbacks callbacks) {
    raku_callbacks = callbacks;
    
    // Check if Python is already initialized
    if (Py_IsInitialized()) {
        PyDateTime_IMPORT;
        return 0;
    }
    
    // Import our module BEFORE initializing Python
    PyImport_AppendInittab("python3", &PyInit_python3);
    
    // Configure Python for embedding
    PyConfig config;
    PyConfig_InitPythonConfig(&config);
    config.isolated = 1;
    config.use_environment = 0;
    
    // Initialize Python
    PyStatus status = Py_InitializeFromConfig(&config);
    PyConfig_Clear(&config);
    
    if (PyStatus_Exception(status)) {
        return -1;
    }
    
    PyDateTime_IMPORT;
    
    return 0;
}

// Cleanup Python interpreter
int python3_destroy_python() {
    return Py_FinalizeEx();
}

// Enhanced error fetching with traceback
void python3_fetch_error(PythonError *error) {
    PyErr_Fetch(&error->type, &error->value, &error->traceback);
    
    if (!error->type) {
        error->formatted_exception = NULL;
        return;
    }
    
    PyErr_NormalizeException(&error->type, &error->value, &error->traceback);
    
    // Format the exception with traceback
    PyObject *tb_module = PyImport_ImportModule("traceback");
    if (tb_module) {
        PyObject *format_func = PyObject_GetAttrString(tb_module, "format_exception");
        if (format_func) {
            PyObject *args = PyTuple_Pack(3, 
                error->type ? error->type : Py_None,
                error->value ? error->value : Py_None, 
                error->traceback ? error->traceback : Py_None);
            
            PyObject *tb_list = PyObject_CallObject(format_func, args);
            if (tb_list) {
                PyObject *tb_str = PyUnicode_Join(PyUnicode_FromString(""), tb_list);
                if (tb_str) {
                    error->formatted_exception = strdup(PyUnicode_AsUTF8(tb_str));
                    Py_DECREF(tb_str);
                }
                Py_DECREF(tb_list);
            }
            Py_DECREF(args);
            Py_DECREF(format_func);
        }
        Py_DECREF(tb_module);
    }
}

// Type checking functions
int python3_is_none(PyObject *obj) {
    return obj == Py_None;
}

int python3_is_bool(PyObject *obj) {
    return PyBool_Check(obj);
}

int python3_is_int(PyObject *obj) {
    return PyLong_Check(obj);
}

int python3_is_float(PyObject *obj) {
    return PyFloat_Check(obj);
}

int python3_is_str(PyObject *obj) {
    return PyUnicode_Check(obj);
}

int python3_is_bytes(PyObject *obj) {
    return PyBytes_Check(obj);
}

int python3_is_list(PyObject *obj) {
    return PyList_Check(obj);
}

int python3_is_tuple(PyObject *obj) {
    return PyTuple_Check(obj);
}

int python3_is_dict(PyObject *obj) {
    return PyDict_Check(obj);
}

int python3_is_set(PyObject *obj) {
    return PySet_Check(obj);
}

int python3_is_callable(PyObject *obj) {
    return PyCallable_Check(obj);
}

int python3_is_module(PyObject *obj) {
    return PyModule_Check(obj);
}

int python3_is_type(PyObject *obj) {
    return PyType_Check(obj);
}

// Conversion functions
long python3_int_to_long(PyObject *obj) {
    return PyLong_AsLong(obj);
}

double python3_float_to_double(PyObject *obj) {
    return PyFloat_AsDouble(obj);
}

int python3_bool_to_int(PyObject *obj) {
    return obj == Py_True ? 1 : 0;
}

const char* python3_str_to_utf8(PyObject *obj, Py_ssize_t *size) {
    return PyUnicode_AsUTF8AndSize(obj, size);
}

const char* python3_bytes_to_buf(PyObject *obj, Py_ssize_t *size) {
    char *buffer;
    if (PyBytes_AsStringAndSize(obj, &buffer, size) == -1) {
        return NULL;
    }
    return buffer;
}

// Object creation functions
PyObject* python3_none() {
    Py_RETURN_NONE;
}

PyObject* python3_bool_from_int(int value) {
    return PyBool_FromLong(value);
}

PyObject* python3_int_from_long(long value) {
    return PyLong_FromLong(value);
}

PyObject* python3_float_from_double(double value) {
    return PyFloat_FromDouble(value);
}

PyObject* python3_str_from_utf8(const char *str, Py_ssize_t size) {
    return PyUnicode_FromStringAndSize(str, size);
}

PyObject* python3_bytes_from_buffer(const char *buf, Py_ssize_t size) {
    return PyBytes_FromStringAndSize(buf, size);
}

// Collection functions
PyObject* python3_list_new(Py_ssize_t size) {
    return PyList_New(size);
}

int python3_list_set_item(PyObject *list, Py_ssize_t index, PyObject *item) {
    return PyList_SetItem(list, index, item);
}

PyObject* python3_list_get_item(PyObject *list, Py_ssize_t index) {
    return PyList_GetItem(list, index);
}

Py_ssize_t python3_list_size(PyObject *list) {
    return PyList_Size(list);
}

PyObject* python3_tuple_new(Py_ssize_t size) {
    return PyTuple_New(size);
}

int python3_tuple_set_item(PyObject *tuple, Py_ssize_t index, PyObject *item) {
    return PyTuple_SetItem(tuple, index, item);
}

PyObject* python3_tuple_get_item(PyObject *tuple, Py_ssize_t index) {
    return PyTuple_GetItem(tuple, index);
}

Py_ssize_t python3_tuple_size(PyObject *tuple) {
    return PyTuple_Size(tuple);
}

PyObject* python3_dict_new() {
    return PyDict_New();
}

int python3_dict_set_item(PyObject *dict, PyObject *key, PyObject *value) {
    return PyDict_SetItem(dict, key, value);
}

PyObject* python3_dict_get_item(PyObject *dict, PyObject *key) {
    return PyDict_GetItem(dict, key);
}

PyObject* python3_dict_keys(PyObject *dict) {
    return PyDict_Keys(dict);
}

PyObject* python3_dict_values(PyObject *dict) {
    return PyDict_Values(dict);
}

PyObject* python3_dict_items(PyObject *dict) {
    return PyDict_Items(dict);
}

Py_ssize_t python3_dict_size(PyObject *dict) {
    return PyDict_Size(dict);
}

// Object operations
PyObject* python3_get_attr(PyObject *obj, const char *name) {
    return PyObject_GetAttrString(obj, name);
}

int python3_set_attr(PyObject *obj, const char *name, PyObject *value) {
    return PyObject_SetAttrString(obj, name, value);
}

int python3_has_attr(PyObject *obj, const char *name) {
    return PyObject_HasAttrString(obj, name);
}

PyObject* python3_dir(PyObject *obj) {
    return PyObject_Dir(obj);
}

PyObject* python3_type(PyObject *obj) {
    return PyObject_Type(obj);
}

PyObject* python3_str(PyObject *obj) {
    return PyObject_Str(obj);
}

PyObject* python3_repr(PyObject *obj) {
    return PyObject_Repr(obj);
}

// Import and execution
PyObject* python3_import(const char *name) {
    return PyImport_ImportModule(name);
}

PyObject* python3_import_from(const char *module, const char *name) {
    PyObject *mod = PyImport_ImportModule(module);
    if (!mod) return NULL;
    
    PyObject *obj = PyObject_GetAttrString(mod, name);
    Py_DECREF(mod);
    return obj;
}

PyObject* python3_eval(const char *code, PyObject *globals, PyObject *locals) {
    if (!globals) {
        globals = PyDict_New();
    }
    if (!locals) {
        locals = globals;
    }
    
    return PyRun_String(code, Py_eval_input, globals, locals);
}

PyObject* python3_exec(const char *code, PyObject *globals, PyObject *locals) {
    if (!globals) {
        globals = PyDict_New();
    }
    if (!locals) {
        locals = globals;
    }
    
    return PyRun_String(code, Py_file_input, globals, locals);
}

// Function calling with better argument handling
PyObject* python3_call(PyObject *callable, PyObject *args, PyObject *kwargs) {
    if (!args) {
        args = PyTuple_New(0);
    }
    
    PyObject *result = PyObject_Call(callable, args, kwargs);
    return result;
}

PyObject* python3_call_method(PyObject *obj, const char *method, PyObject *args, PyObject *kwargs) {
    PyObject *meth = PyObject_GetAttrString(obj, method);
    if (!meth) return NULL;
    
    if (!args) {
        args = PyTuple_New(0);
    }
    
    PyObject *result = PyObject_Call(meth, args, kwargs);
    Py_DECREF(meth);
    return result;
}

// Reference counting
void python3_inc_ref(PyObject *obj) {
    Py_XINCREF(obj);
}

void python3_dec_ref(PyObject *obj) {
    Py_XDECREF(obj);
}

Py_ssize_t python3_ref_count(PyObject *obj) {
    return Py_REFCNT(obj);
}

// Raku object wrapper
typedef struct {
    PyObject_HEAD
    int raku_index;
} RakuObject;

static PyObject* raku_object_new(PyTypeObject *type, PyObject *args, PyObject *kwds) {
    RakuObject *self = (RakuObject *)type->tp_alloc(type, 0);
    if (self != NULL) {
        self->raku_index = -1;
    }
    return (PyObject *)self;
}

static int raku_object_init(RakuObject *self, PyObject *args, PyObject *kwds) {
    if (!PyArg_ParseTuple(args, "i", &self->raku_index)) {
        return -1;
    }
    return 0;
}

static PyObject* raku_object_call(RakuObject *self, PyObject *args, PyObject *kwds) {
    PyObject *error = NULL;
    PyObject *result = raku_callbacks.call_raku_object(self->raku_index, args, &error);
    
    if (error) {
        PyErr_SetObject(PyExc_RuntimeError, error);
        Py_DECREF(error);
        return NULL;
    }
    
    return result;
}

static PyObject* raku_object_getattr(RakuObject *self, char *name) {
    // First check if it's a special attribute
    if (strcmp(name, "__dict__") == 0 || strcmp(name, "__class__") == 0) {
        return PyObject_GenericGetAttr((PyObject *)self, PyUnicode_FromString(name));
    }
    
    // Otherwise delegate to Raku
    PyObject *error = NULL;
    PyObject *args = PyTuple_Pack(1, PyUnicode_FromString(name));
    PyObject *result = raku_callbacks.call_raku_method(self->raku_index, "__getattr__", args, &error);
    Py_DECREF(args);
    
    if (error) {
        PyErr_SetObject(PyExc_AttributeError, error);
        Py_DECREF(error);
        return NULL;
    }
    
    return result;
}

static PyTypeObject RakuObjectType = {
    PyVarObject_HEAD_INIT(NULL, 0)
    .tp_name = "python3.RakuObject",
    .tp_doc = "Raku object wrapper",
    .tp_basicsize = sizeof(RakuObject),
    .tp_itemsize = 0,
    .tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE,
    .tp_new = raku_object_new,
    .tp_init = (initproc)raku_object_init,
    .tp_call = (ternaryfunc)raku_object_call,
    .tp_getattro = (getattrofunc)raku_object_getattr,
};

// Module methods
static PyObject* python3_call_raku(PyObject *self, PyObject *args) {
    int index;
    PyObject *params;
    
    if (!PyArg_ParseTuple(args, "iO", &index, &params)) {
        return NULL;
    }
    
    PyObject *error = NULL;
    PyObject *result = raku_callbacks.call_raku_object(index, params, &error);
    
    if (error) {
        PyErr_SetObject(PyExc_RuntimeError, error);
        Py_DECREF(error);
        return NULL;
    }
    
    return result;
}

static PyObject* python3_invoke_raku(PyObject *self, PyObject *args) {
    int index;
    const char *method;
    PyObject *params;
    
    if (!PyArg_ParseTuple(args, "isO", &index, &method, &params)) {
        return NULL;
    }
    
    PyObject *error = NULL;
    PyObject *result = raku_callbacks.call_raku_method(index, (char *)method, params, &error);
    
    if (error) {
        PyErr_SetObject(PyExc_RuntimeError, error);
        Py_DECREF(error);
        return NULL;
    }
    
    return result;
}

static PyMethodDef python3_methods[] = {
    {"call_raku", python3_call_raku, METH_VARARGS, "Call a Raku object"},
    {"invoke_raku", python3_invoke_raku, METH_VARARGS, "Invoke a method on a Raku object"},
    {NULL, NULL, 0, NULL}
};

static struct PyModuleDef python3_module = {
    PyModuleDef_HEAD_INIT,
    "python3",
    "Inline::Python3 helper module",
    -1,
    python3_methods
};

PyObject* PyInit_python3(void) {
    PyObject *m = PyModule_Create(&python3_module);
    if (m == NULL) {
        return NULL;
    }
    
    if (PyType_Ready(&RakuObjectType) < 0) {
        return NULL;
    }
    
    Py_INCREF(&RakuObjectType);
    if (PyModule_AddObject(m, "RakuObject", (PyObject *)&RakuObjectType) < 0) {
        Py_DECREF(&RakuObjectType);
        Py_DECREF(m);
        return NULL;
    }
    
    return m;
}

// ===== OPTIMIZED FUNCTIONS =====
// Performance optimizations for common operations

// Zero-copy string conversion when possible
const char* python3_str_to_utf8_zero_copy(PyObject *obj, Py_ssize_t *size) {
    // Check if it's a compact ASCII string (common case)
    if (PyUnicode_IS_COMPACT_ASCII(obj)) {
        *size = PyUnicode_GET_LENGTH(obj);
        return (const char*)PyUnicode_1BYTE_DATA(obj);
    }
    
    // Fall back to regular conversion
    return PyUnicode_AsUTF8AndSize(obj, size);
}

// Bulk type checking for efficient type dispatch
void python3_check_type_bulk(PyObject *obj, uint8_t *type_info) {
    // Check all common types at once
    type_info[0] = (obj == Py_None);
    type_info[1] = PyBool_Check(obj);
    type_info[2] = PyLong_Check(obj);
    type_info[3] = PyFloat_Check(obj);
    type_info[4] = PyUnicode_Check(obj);
    type_info[5] = PyBytes_Check(obj);
    type_info[6] = PyList_Check(obj);
    type_info[7] = PyTuple_Check(obj);
    type_info[8] = PyDict_Check(obj);
    type_info[9] = PyCallable_Check(obj);
}

// Optimized integer creation
PyObject* python3_int_from_long_opt(long value) {
    return PyLong_FromLong(value);
}

// Fast list creation from array
PyObject* python3_list_from_array(PyObject **items, Py_ssize_t size) {
    PyObject *list = PyList_New(size);
    if (!list) return NULL;
    
    for (Py_ssize_t i = 0; i < size; i++) {
        Py_INCREF(items[i]);
        PyList_SET_ITEM(list, i, items[i]);  // Steals reference
    }
    
    return list;
}

// Fast tuple creation from array
PyObject* python3_tuple_from_array(PyObject **items, Py_ssize_t size) {
    PyObject *tuple = PyTuple_New(size);
    if (!tuple) return NULL;
    
    for (Py_ssize_t i = 0; i < size; i++) {
        Py_INCREF(items[i]);
        PyTuple_SET_ITEM(tuple, i, items[i]);  // Steals reference
    }
    
    return tuple;
}

// Placeholder cache functions (implemented in Raku for flexibility)
PyObject* python3_str_from_utf8_cached(const char *str, Py_ssize_t size) {
    return PyUnicode_FromStringAndSize(str, size);
}

PyObject* python3_get_method_cached(PyObject *obj, const char *name) {
    return PyObject_GetAttrString(obj, name);
}

PyObject* python3_call_fast(PyObject *func, PyObject *args, PyObject *kwargs) {
    if (!kwargs || PyDict_Size(kwargs) == 0) {
        return PyObject_CallObject(func, args);
    }
    return PyObject_Call(func, args, kwargs);
}

void python3_get_cache_stats(uint64_t *hits, uint64_t *misses, uint64_t *cached) {
    *hits = 0;
    *misses = 0;
    *cached = 0;
}

void python3_clear_caches(void) {
    // Caches are managed in Raku
}
