// NumPy integration helpers for zero-copy operations
#include <Python.h>
#include <numpy/arrayobject.h>
#include <numpy/ndarraytypes.h>

// Initialize NumPy C API
static int numpy_initialized = 0;

static void ensure_numpy_initialized() {
    if (!numpy_initialized) {
        import_array();
        numpy_initialized = 1;
    }
}

// Check if object is a NumPy array
int python3_numpy_is_array(PyObject *obj) {
    ensure_numpy_initialized();
    return PyArray_Check(obj) ? 1 : 0;
}

// Get array data pointer
void* python3_numpy_array_data(PyObject *obj) {
    if (!PyArray_Check(obj)) return NULL;
    return PyArray_DATA((PyArrayObject*)obj);
}

// Get array type number
int python3_numpy_array_type(PyObject *obj) {
    if (!PyArray_Check(obj)) return -1;
    return PyArray_TYPE((PyArrayObject*)obj);
}

// Get item size
int64_t python3_numpy_array_itemsize(PyObject *obj) {
    if (!PyArray_Check(obj)) return -1;
    return PyArray_ITEMSIZE((PyArrayObject*)obj);
}

// Get array flags
int python3_numpy_array_flags(PyObject *obj) {
    if (!PyArray_Check(obj)) return 0;
    return PyArray_FLAGS((PyArrayObject*)obj);
}

// Get dimensions
void python3_numpy_array_dims(PyObject *obj, int64_t *dims) {
    if (!PyArray_Check(obj)) return;
    
    PyArrayObject *arr = (PyArrayObject*)obj;
    int ndim = PyArray_NDIM(arr);
    npy_intp *shape = PyArray_DIMS(arr);
    
    for (int i = 0; i < ndim; i++) {
        dims[i] = shape[i];
    }
}

// Get strides
void python3_numpy_array_strides(PyObject *obj, int64_t *strides) {
    if (!PyArray_Check(obj)) return;
    
    PyArrayObject *arr = (PyArrayObject*)obj;
    int ndim = PyArray_NDIM(arr);
    npy_intp *arr_strides = PyArray_STRIDES(arr);
    
    for (int i = 0; i < ndim; i++) {
        strides[i] = arr_strides[i];
    }
}

// Get array struct (for direct access)
PyArrayObject* python3_numpy_get_array_struct(PyObject *obj) {
    if (!PyArray_Check(obj)) return NULL;
    return (PyArrayObject*)obj;
}

// Create array from data pointer (zero-copy)
PyObject* python3_numpy_from_data(void *data, int type, int nd, int64_t *dims, int64_t *strides, int flags) {
    ensure_numpy_initialized();
    
    npy_intp *np_dims = malloc(nd * sizeof(npy_intp));
    npy_intp *np_strides = strides ? malloc(nd * sizeof(npy_intp)) : NULL;
    
    for (int i = 0; i < nd; i++) {
        np_dims[i] = dims[i];
        if (np_strides) np_strides[i] = strides[i];
    }
    
    PyObject *arr = PyArray_New(&PyArray_Type, nd, np_dims, type, np_strides, 
                                data, 0, flags, NULL);
    
    free(np_dims);
    if (np_strides) free(np_strides);
    
    return arr;
}

// Fast element access for contiguous arrays
double python3_numpy_get_double(PyObject *obj, int64_t index) {
    if (!PyArray_Check(obj)) return 0.0;
    
    PyArrayObject *arr = (PyArrayObject*)obj;
    if (PyArray_TYPE(arr) != NPY_DOUBLE) return 0.0;
    if (!PyArray_IS_C_CONTIGUOUS(arr)) return 0.0;
    
    double *data = (double*)PyArray_DATA(arr);
    return data[index];
}

void python3_numpy_set_double(PyObject *obj, int64_t index, double value) {
    if (!PyArray_Check(obj)) return;
    
    PyArrayObject *arr = (PyArrayObject*)obj;
    if (PyArray_TYPE(arr) != NPY_DOUBLE) return;
    if (!PyArray_IS_C_CONTIGUOUS(arr)) return;
    if (!(PyArray_FLAGS(arr) & NPY_ARRAY_WRITEABLE)) return;
    
    double *data = (double*)PyArray_DATA(arr);
    data[index] = value;
}

// Fast bulk operations
void python3_numpy_add_scalar_double(PyObject *obj, double scalar) {
    if (!PyArray_Check(obj)) return;
    
    PyArrayObject *arr = (PyArrayObject*)obj;
    if (PyArray_TYPE(arr) != NPY_DOUBLE) return;
    if (!PyArray_IS_C_CONTIGUOUS(arr)) return;
    if (!(PyArray_FLAGS(arr) & NPY_ARRAY_WRITEABLE)) return;
    
    double *data = (double*)PyArray_DATA(arr);
    npy_intp size = PyArray_SIZE(arr);
    
    for (npy_intp i = 0; i < size; i++) {
        data[i] += scalar;
    }
}

// SIMD-optimized operations (if available)
#ifdef __AVX__
#include <immintrin.h>

void python3_numpy_add_arrays_double_avx(PyObject *a, PyObject *b, PyObject *result) {
    if (!PyArray_Check(a) || !PyArray_Check(b) || !PyArray_Check(result)) return;
    
    PyArrayObject *arr_a = (PyArrayObject*)a;
    PyArrayObject *arr_b = (PyArrayObject*)b;
    PyArrayObject *arr_result = (PyArrayObject*)result;
    
    // Check all arrays are double, contiguous, and same size
    if (PyArray_TYPE(arr_a) != NPY_DOUBLE || 
        PyArray_TYPE(arr_b) != NPY_DOUBLE || 
        PyArray_TYPE(arr_result) != NPY_DOUBLE) return;
        
    if (!PyArray_IS_C_CONTIGUOUS(arr_a) || 
        !PyArray_IS_C_CONTIGUOUS(arr_b) || 
        !PyArray_IS_C_CONTIGUOUS(arr_result)) return;
    
    npy_intp size = PyArray_SIZE(arr_a);
    if (size != PyArray_SIZE(arr_b) || size != PyArray_SIZE(arr_result)) return;
    
    double *data_a = (double*)PyArray_DATA(arr_a);
    double *data_b = (double*)PyArray_DATA(arr_b);
    double *data_result = (double*)PyArray_DATA(arr_result);
    
    // Process 4 doubles at a time with AVX
    npy_intp simd_size = size - (size % 4);
    for (npy_intp i = 0; i < simd_size; i += 4) {
        __m256d va = _mm256_loadu_pd(&data_a[i]);
        __m256d vb = _mm256_loadu_pd(&data_b[i]);
        __m256d vresult = _mm256_add_pd(va, vb);
        _mm256_storeu_pd(&data_result[i], vresult);
    }
    
    // Handle remaining elements
    for (npy_intp i = simd_size; i < size; i++) {
        data_result[i] = data_a[i] + data_b[i];
    }
}
#endif

// Type string from type number
const char* python3_numpy_type_string(int type_num) {
    switch(type_num) {
        case NPY_BOOL: return "bool";
        case NPY_BYTE: return "int8";
        case NPY_UBYTE: return "uint8";
        case NPY_SHORT: return "int16";
        case NPY_USHORT: return "uint16";
        case NPY_INT: return "int32";
        case NPY_UINT: return "uint32";
        case NPY_LONG: return "int64";
        case NPY_ULONG: return "uint64";
        case NPY_FLOAT: return "float32";
        case NPY_DOUBLE: return "float64";
        default: return "unknown";
    }
}