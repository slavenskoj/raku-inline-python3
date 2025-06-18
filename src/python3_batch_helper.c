// Batch conversion helpers for efficient array operations
#include <Python.h>
#include <string.h>

// Batch convert integers to Python
void python3_batch_int_to_py(int64_t *values, int32_t count, PyObject **results) {
    for (int32_t i = 0; i < count; i++) {
        // Use cached integers for small values
        if (values[i] >= -5 && values[i] <= 256) {
            results[i] = PyLong_FromLong(values[i]);
        } else {
            results[i] = PyLong_FromLongLong(values[i]);
        }
    }
}

// Batch convert floats to Python
void python3_batch_num_to_py(double *values, int32_t count, PyObject **results) {
    for (int32_t i = 0; i < count; i++) {
        results[i] = PyFloat_FromDouble(values[i]);
    }
}

// Batch convert strings to Python
void python3_batch_str_to_py(char **values, int32_t count, PyObject **results) {
    for (int32_t i = 0; i < count; i++) {
        results[i] = PyUnicode_FromString(values[i]);
    }
}

// Batch convert Python integers to C
void python3_batch_py_to_int(PyObject **values, int32_t count, int64_t *results) {
    for (int32_t i = 0; i < count; i++) {
        if (PyLong_Check(values[i])) {
            results[i] = PyLong_AsLongLong(values[i]);
        } else {
            results[i] = 0;  // Default for non-integers
        }
    }
}

// Batch convert Python floats to C
void python3_batch_py_to_num(PyObject **values, int32_t count, double *results) {
    for (int32_t i = 0; i < count; i++) {
        if (PyFloat_Check(values[i])) {
            results[i] = PyFloat_AsDouble(values[i]);
        } else if (PyLong_Check(values[i])) {
            results[i] = (double)PyLong_AsLongLong(values[i]);
        } else {
            results[i] = 0.0;  // Default for non-numbers
        }
    }
}

// Batch convert Python strings to C
void python3_batch_py_to_str(PyObject **values, int32_t count, char **results) {
    for (int32_t i = 0; i < count; i++) {
        if (PyUnicode_Check(values[i])) {
            const char *str = PyUnicode_AsUTF8(values[i]);
            results[i] = strdup(str);  // Caller must free
        } else {
            results[i] = strdup("");  // Empty string for non-strings
        }
    }
}

// Create Python list from array of PyObject pointers
PyObject* python3_create_list_from_pointers(PyObject **values, int32_t count) {
    PyObject *list = PyList_New(count);
    if (!list) return NULL;
    
    for (int32_t i = 0; i < count; i++) {
        Py_INCREF(values[i]);
        PyList_SET_ITEM(list, i, values[i]);
    }
    
    return list;
}

// Create Python tuple from array of PyObject pointers
PyObject* python3_create_tuple_from_pointers(PyObject **values, int32_t count) {
    PyObject *tuple = PyTuple_New(count);
    if (!tuple) return NULL;
    
    for (int32_t i = 0; i < count; i++) {
        Py_INCREF(values[i]);
        PyTuple_SET_ITEM(tuple, i, values[i]);
    }
    
    return tuple;
}

// Extract pointers from Python list
void python3_list_to_pointer_array(PyObject *list, PyObject **results) {
    if (!PyList_Check(list)) return;
    
    Py_ssize_t size = PyList_Size(list);
    for (Py_ssize_t i = 0; i < size; i++) {
        results[i] = PyList_GetItem(list, i);
    }
}

// Optimized homogeneous array operations
PyObject* python3_create_int_list(int64_t *values, int32_t count) {
    PyObject *list = PyList_New(count);
    if (!list) return NULL;
    
    for (int32_t i = 0; i < count; i++) {
        PyObject *num = PyLong_FromLongLong(values[i]);
        PyList_SET_ITEM(list, i, num);
    }
    
    return list;
}

PyObject* python3_create_float_list(double *values, int32_t count) {
    PyObject *list = PyList_New(count);
    if (!list) return NULL;
    
    for (int32_t i = 0; i < count; i++) {
        PyObject *num = PyFloat_FromDouble(values[i]);
        PyList_SET_ITEM(list, i, num);
    }
    
    return list;
}

// Type checking for homogeneous optimization
int python3_list_is_homogeneous_int(PyObject *list) {
    if (!PyList_Check(list)) return 0;
    
    Py_ssize_t size = PyList_Size(list);
    for (Py_ssize_t i = 0; i < size; i++) {
        PyObject *item = PyList_GetItem(list, i);
        if (!PyLong_Check(item)) return 0;
    }
    
    return 1;
}

int python3_list_is_homogeneous_float(PyObject *list) {
    if (!PyList_Check(list)) return 0;
    
    Py_ssize_t size = PyList_Size(list);
    for (Py_ssize_t i = 0; i < size; i++) {
        PyObject *item = PyList_GetItem(list, i);
        if (!PyFloat_Check(item) && !PyLong_Check(item)) return 0;
    }
    
    return 1;
}

int python3_list_is_homogeneous_str(PyObject *list) {
    if (!PyList_Check(list)) return 0;
    
    Py_ssize_t size = PyList_Size(list);
    for (Py_ssize_t i = 0; i < size; i++) {
        PyObject *item = PyList_GetItem(list, i);
        if (!PyUnicode_Check(item)) return 0;
    }
    
    return 1;
}

// Bulk operations with SIMD optimization (when available)
#ifdef __SSE2__
#include <emmintrin.h>

void python3_batch_add_int_arrays_sse2(int64_t *a, int64_t *b, int64_t *result, int32_t count) {
    int32_t simd_count = count - (count % 2);
    
    for (int32_t i = 0; i < simd_count; i += 2) {
        __m128i va = _mm_loadu_si128((__m128i*)&a[i]);
        __m128i vb = _mm_loadu_si128((__m128i*)&b[i]);
        __m128i vr = _mm_add_epi64(va, vb);
        _mm_storeu_si128((__m128i*)&result[i], vr);
    }
    
    // Handle remaining elements
    for (int32_t i = simd_count; i < count; i++) {
        result[i] = a[i] + b[i];
    }
}
#endif

// Memory pool for temporary allocations
typedef struct {
    void *memory;
    size_t size;
    size_t used;
} MemoryPool;

static MemoryPool batch_pool = {NULL, 0, 0};

void* batch_pool_alloc(size_t size) {
    if (batch_pool.used + size > batch_pool.size) {
        // Grow pool
        size_t new_size = batch_pool.size * 2;
        if (new_size < size + batch_pool.used) {
            new_size = size + batch_pool.used;
        }
        
        void *new_memory = realloc(batch_pool.memory, new_size);
        if (!new_memory) return NULL;
        
        batch_pool.memory = new_memory;
        batch_pool.size = new_size;
    }
    
    void *ptr = (char*)batch_pool.memory + batch_pool.used;
    batch_pool.used += size;
    return ptr;
}

void batch_pool_reset() {
    batch_pool.used = 0;
}

void batch_pool_free() {
    free(batch_pool.memory);
    batch_pool.memory = NULL;
    batch_pool.size = 0;
    batch_pool.used = 0;
}