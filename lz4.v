module lz4

#flag -llz4
#flag -I @VMODROOT/ext
#flag -L @VMODROOT/ext

#include "lz4frame.h"
[typedef]
struct C.LZ4F_preferences_t {}

fn C.LZ4F_compressFrameBound(usize, &C.LZ4F_preferences_t) usize

// size_t LZ4F_compressFrame(void* dstBuffer, size_t dstCapacity,
//                                 const void* srcBuffer, size_t srcSize,
//                                 const LZ4F_preferences_t* preferencesPtr);
fn C.LZ4F_compressFrame( dst_buffer voidptr, dst_cap usize
                       , src_buffer voidptr, src_size usize
                       , pref &C.LZ4F_preferences_t) usize

// LZ4FLIB_API unsigned    LZ4F_isError(LZ4F_errorCode_t code);   /**< tells when a function result is an error code */
fn C.LZ4F_isError(code C.LZ4F_errorCode_t) u32
// LZ4FLIB_API const char* LZ4F_getErrorName(LZ4F_errorCode_t code);   /**< return error code string; for debugging */
fn C.LZ4F_getErrorName(code C.LZ4F_errorCode_t) charptr


// LZ4FLIB_API unsigned LZ4F_getVersion(void);
fn C.LZ4F_getVersion() u32

// LZ4FLIB_API size_t LZ4F_getFrameInfo(LZ4F_dctx* dctx,
//                                      LZ4F_frameInfo_t* frameInfoPtr,
//                                      const void* srcBuffer, size_t* srcSizePtr);
[typedef]
struct C.LZ4F_frameInfo_t {
    contentSize u64
}

fn C.LZ4F_getFrameInfo( dctx &C.LZ4F_dctx
                    , frameInfoPtr &C.LZ4F_frameInfo_t
                    , srcBuffer voidptr, srcSizePtr &usize) usize



[typedef]
struct C.LZ4F_decompressOptions_t {}

// size_t LZ4F_decompress(LZ4F_dctx* dctx,
//                                    void* dstBuffer, size_t* dstSizePtr,
//                                    const void* srcBuffer, size_t* srcSizePtr,
//                                    const LZ4F_decompressOptions_t* dOptPtr);
fn C.LZ4F_decompress(dctx &C.LZ4F_dctx,
                    dstBuffer voidptr, dstSizePtr &usize,
                    srcBuffer voidptr, srcSizePtr &usize,
                    dOptPtr &C.LZ4F_decompressOptions_t ) usize 

/*! LZ4F_createDecompressionContext() :
 *  Create an LZ4F_dctx object, to track all decompression operations.
 *  The version provided MUST be LZ4F_VERSION.
 *  The function provides a pointer to an allocated and initialized LZ4F_dctx object.
 *  The result is an errorCode, which can be tested using LZ4F_isError().
 *  dctx memory can be released using LZ4F_freeDecompressionContext();
 *  Result of LZ4F_freeDecompressionContext() indicates current state of decompressionContext when being released.
 *  That is, it should be == 0 if decompression has been completed fully and correctly.
 */
//LZ4F_errorCode_t LZ4F_createDecompressionContext(LZ4F_dctx** dctxPtr, unsigned version);
[typedef]
struct C.LZ4F_errorCode_t {}

type ErrorCode = C.LZ4F_errorCode_t
type SizeOrError = ErrorCode | usize


[typedef]
struct C.LZ4F_dctx {}

fn C.LZ4F_createDecompressionContext(dctxPtr &&C.LZ4F_dctx, version u32) C.LZ4F_errorCode_t 

//LZ4F_errorCode_t LZ4F_freeDecompressionContext(LZ4F_dctx* dctx);
fn C.LZ4F_freeDecompressionContext(dctx &C.LZ4F_dctx) C.LZ4F_errorCode_t

pub fn compress(data []byte) ?[]byte {

    cap := C.LZ4F_compressFrameBound(data.len, 0)
    mut len := get_size(cap)?

    mut dst_buffer := []byte{len: len}

    res := C.LZ4F_compressFrame( dst_buffer.data
                               , cap
                               , data.data
                               , data.len
                               , 0
                               )

    len = get_size(res)?
    dst_buffer.trim(len)
    return dst_buffer
}

pub fn decompress(data []byte) ?[]byte {
    mut dctx := &C.LZ4F_dctx(0)
    version := C.LZ4F_getVersion()
    // println("version: ${version}")
    mut e := C.LZ4F_createDecompressionContext(&dctx, version)
    get_size(ErrorCode(e))?

    // release decompression context when leaving the function
    defer {
        C.LZ4F_freeDecompressionContext(dctx)
    }

    mut info := C.LZ4F_frameInfo_t{}
    mut src_size := usize(data.len)

    mut s := C.LZ4F_getFrameInfo(dctx,  &info, data.data, &src_size)
    get_size(s)?

    println(info.contentSize)
    
    mut dst := []byte{cap: 4 * data.len}

    
    mut src := data.data
    unsafe {
         src = &byte(src) + src_size
         src_size = usize(data.len)
    }

    mut buffer := []byte{len: 4 * data.len}
    buf_size := usize(buffer.len)
    opt := C.LZ4F_decompressOptions_t{}


    for s > 0 {
        ss := src_size
        s  = C.LZ4F_decompress(dctx, buffer.data, &buf_size, src, &ss, &opt)
        get_size(s)?
        unsafe {
            src = &byte(src) +  ss
        }
        src_size -= ss
        buffer.trim(int(buf_size))
        dst << buffer
    }
    return dst
}


fn get_size(s SizeOrError) ?int{
    e := match s {
        usize      { C.LZ4F_errorCode_t(s) }
        ErrorCode  { s }
    }
    if C.LZ4F_isError(e) > 0 {
        error_name := unsafe {C.LZ4F_getErrorName(e).vstring()}
        error(error_name)
    }

    if s is usize {
        return int(s)
    }
    return 0
}