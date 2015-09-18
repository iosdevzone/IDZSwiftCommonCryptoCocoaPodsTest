//
//  Cryptor.swift
//  SwiftCommonCrypto
//
//  Created by idz on 9/19/14.
//  Copyright (c) 2014 iOS Developer Zone. All rights reserved.
//

import Foundation
import CommonCrypto

/**
    Encrypts or decrypts return results as they become available.

    :note: The underlying cipher may be a block or a stream cipher.

    Use for large files or network streams.

    For small, in-memory buffers Cryptor may be easier to use.
*/
public class StreamCryptor
{
    public enum Operation
    {
        case Encrypt, Decrypt
        
        func nativeValue() -> CCOperation {
            switch self {
            case Encrypt : return CCOperation(kCCEncrypt)
            case Decrypt : return CCOperation(kCCDecrypt)
            }
        }
    }
    
    public enum Algorithm
    {
        case AES, DES, TripleDES, CAST, RC2, Blowfish
        
        public func blockSize() -> Int {
            switch self {
            case AES : return kCCBlockSizeAES128
            case DES : return kCCBlockSizeDES
            case TripleDES : return kCCBlockSize3DES
            case CAST : return kCCBlockSizeCAST
            case RC2: return kCCBlockSizeRC2
            case Blowfish : return kCCBlockSizeBlowfish
            }
        }
        
        func nativeValue() -> CCAlgorithm
        {
            switch self {
            case AES : return CCAlgorithm(kCCAlgorithmAES)
            case DES : return CCAlgorithm(kCCAlgorithmDES)
            case TripleDES : return CCAlgorithm(kCCAlgorithm3DES)
            case CAST : return CCAlgorithm(kCCAlgorithmCAST)
            case RC2: return CCAlgorithm(kCCAlgorithmRC2)
            case Blowfish : return CCAlgorithm(kCCAlgorithmBlowfish)
            }
        }
    }
    
    /*
    * It turns out to be rather tedious to reprent ORable
    * bitmask style options in Swift. I would love to
    * to say that I was smart enough to figure out the
    * magic incantions below for myself, but it was, in fact,
    * NSHipster
    * From: http://nshipster.com/rawoptionsettype/
    */
    public struct Options : OptionSetType, BooleanType {
        private var value: UInt = 0
        public typealias RawValue = UInt
        public var rawValue : UInt { return self.value }
        
        public init(_ rawValue: UInt) {
            self.value = rawValue
        }
        
        
        // Needed for 1.1 RawRepresentable
        public init(rawValue: UInt) {
            self.value = rawValue
        }
        
        // Needed for 1.1 NilLiteralConverable
        public init(nilLiteral: ())
        {
            
        }
        
        // Needed for 1.0 _RawOptionSet
        public static func fromMask(raw: UInt) -> Options {
            return self.init(raw)
        }
        
        public static func fromRaw(raw: UInt) -> Options? {
            return self.init(raw)
        }
        
        public func toRaw() -> UInt {
            return value
        }
        
        public var boolValue: Bool {
            return value != 0
        }
        
        public static var allZeros: Options {
            return self.init(0)
        }
        
        public static func convertFromNilLiteral() -> Options {
            return self.init(0)
        }
        
        public static var None: Options           { return self.init(0) }
        public static var PKCS7Padding: Options    { return self.init(UInt(kCCOptionPKCS7Padding)) }
        public static var ECBMode: Options      { return self.init(UInt(kCCOptionECBMode)) }
    }
    

    
    /**
        The status code resulting from the last method call to this Cryptor.
        Used to get additional information when optional chaining collapes.
    */
    public var status : Status = .Success

    //MARK: - High-level interface
    /**
        Creates a new StreamCryptor
    
        - parameter operation: the operation to perform see Operation (Encrypt, Decrypt)
        - parameter algorithm: the algorithm to use see Algorithm (AES, DES, TripleDES, CAST, RC2, Blowfish)
        - parameter key: a byte array containing key data
        - parameter iv: a byte array containing initialization vector
    */
    public convenience init(operation: Operation, algorithm: Algorithm, options: Options, key: [UInt8],
        iv : [UInt8])
    {
        self.init(operation:operation, algorithm:algorithm, options:options, keyBuffer:key, keyByteCount:key.count, ivBuffer:iv)
    }
    /**
        Creates a new StreamCryptor
        
        - parameter operation: the operation to perform see Operation (Encrypt, Decrypt)
        - parameter algorithm: the algorithm to use see Algorithm (AES, DES, TripleDES, CAST, RC2, Blowfish)
        - parameter key: a string containing key data (will be interpreted as UTF8)
        - parameter iv: a string containing initialization vector data (will be interpreted as UTF8)
    */
    public convenience init(operation: Operation, algorithm: Algorithm, options: Options, key: String,
        iv : String)
    {
        self.init(operation:operation, algorithm:algorithm, options:options, keyBuffer:key, keyByteCount:key.lengthOfBytesUsingEncoding(NSUTF8StringEncoding), ivBuffer:iv)
    }
    /**
        Add the contents of an Objective-C NSData buffer to the current encryption/decryption operation.
        
        - parameter dataIn: the input data
        - parameter byteArrayOut: output data
        - returns: a tuple containing the number of output bytes produced and the status (see Status)
    */
    public func update(dataIn: NSData, inout byteArrayOut: [UInt8]) -> (Int, Status)
    {
        let dataOutAvailable = byteArrayOut.count
        var dataOutMoved = 0
        update(dataIn.bytes, byteCountIn: dataIn.length, bufferOut: &byteArrayOut, byteCapacityOut: dataOutAvailable, byteCountOut: &dataOutMoved)
        return (dataOutMoved, self.status)
    }
    /**
        Add the contents of a Swift byte array to the current encryption/decryption operation.

        - parameter byteArrayIn: the input data
        - parameter byteArrayOut: output data
        - returns: a tuple containing the number of output bytes produced and the status (see Status)
    */
    public func update(byteArrayIn: [UInt8], inout byteArrayOut: [UInt8]) -> (Int, Status)
    {
        let dataOutAvailable = byteArrayOut.count
        var dataOutMoved = 0
        update(byteArrayIn, byteCountIn: byteArrayIn.count, bufferOut: &byteArrayOut, byteCapacityOut: dataOutAvailable, byteCountOut: &dataOutMoved)
        return (dataOutMoved, self.status)
    }
    /**
        Add the contents of a string (interpreted as UTF8) to the current encryption/decryption operation.

        - parameter byteArrayIn: the input data
        - parameter byteArrayOut: output data
        - returns: a tuple containing the number of output bytes produced and the status (see Status)
    */
    public func update(stringIn: String, inout byteArrayOut: [UInt8]) -> (Int, Status)
    {
        let dataOutAvailable = byteArrayOut.count
        var dataOutMoved = 0
        update(stringIn, byteCountIn: stringIn.lengthOfBytesUsingEncoding(NSUTF8StringEncoding), bufferOut: &byteArrayOut, byteCapacityOut: dataOutAvailable, byteCountOut: &dataOutMoved)
        return (dataOutMoved, self.status)
    }
    /**
        Retrieves all remaining encrypted or decrypted data from this cryptor.

        :note: If the underlying algorithm is an block cipher and the padding option has
        not been specified and the cumulative input to the cryptor has not been an integral
        multiple of the block length this will fail with an alignment error.

        :note: This method updates the status property

        - parameter byteArrayOut: the output bffer        
        - returns: a tuple containing the number of output bytes produced and the status (see Status)
    */
    public func final(inout byteArrayOut: [UInt8]) -> (Int, Status)
    {
        let dataOutAvailable = byteArrayOut.count
        var dataOutMoved = 0
        final(&byteArrayOut, byteCapacityOut: dataOutAvailable, byteCountOut: &dataOutMoved)
        return (dataOutMoved, self.status)
    }
    
    // MARK: - Low-level interface
    /**
        - parameter operation: the operation to perform see Operation (Encrypt, Decrypt)
        - parameter algorithm: the algorithm to use see Algorithm (AES, DES, TripleDES, CAST, RC2, Blowfish)
        - parameter keyBuffer: pointer to key buffer
        - parameter keyByteCount: number of bytes in the key
        - parameter ivBuffer: initialization vector buffer
    */
    public init(operation: Operation, algorithm: Algorithm, options: Options, keyBuffer: UnsafePointer<Void>,
        keyByteCount: Int, ivBuffer: UnsafePointer<Void>)
    {
        let rawStatus = CCCryptorCreate(operation.nativeValue(), algorithm.nativeValue(), CCOptions(options.toRaw()), keyBuffer, keyByteCount, ivBuffer, context)
        if let status = Status.fromRaw(rawStatus)
        {
            self.status = status
        }
        else
        {
            NSLog("FATAL_ERROR: CCCryptorCreate returned unexpected status (\(rawStatus)).")
            fatalError("CCCryptorCreate returned unexpected status.")
        }
    }
    /**
        - parameter bufferIn: pointer to input buffer
        - parameter inByteCount: number of bytes contained in input buffer 
        - parameter bufferOut: pointer to output buffer
        - parameter outByteCapacity: capacity of the output buffer in bytes
        - parameter outByteCount: on successful completion, the number of bytes written to the output buffer
        - returns: 
    */
    public func update(bufferIn: UnsafePointer<Void>, byteCountIn: Int, bufferOut: UnsafeMutablePointer<Void>, byteCapacityOut : Int, inout byteCountOut : Int) -> Status
    {
        if(self.status == Status.Success)
        {
            let rawStatus = CCCryptorUpdate(context.memory, bufferIn, byteCountIn, bufferOut, byteCapacityOut, &byteCountOut)
            if let status = Status.fromRaw(rawStatus)
            {
                self.status =  status

            }
            else
            {
                NSLog("FATAL_ERROR: CCCryptorUpdate returned unexpected status (\(rawStatus)).")
                fatalError("CCCryptorUpdate returned unexpected status.")
            }
        }
        return self.status
    }
    /**
        Retrieves all remaining encrypted or decrypted data from this cryptor.
        
        :note: If the underlying algorithm is an block cipher and the padding option has
        not been specified and the cumulative input to the cryptor has not been an integral 
        multiple of the block length this will fail with an alignment error.
    
        :note: This method updates the status property
        
        - parameter bufferOut: pointer to output buffer
        - parameter outByteCapacity: capacity of the output buffer in bytes
        - parameter outByteCount: on successful completion, the number of bytes written to the output buffer
    */
    public func final(bufferOut: UnsafeMutablePointer<Void>, byteCapacityOut : Int, inout byteCountOut : Int) -> Status
    {
        if(self.status == Status.Success)
        {
            let rawStatus = CCCryptorFinal(context.memory, bufferOut, byteCapacityOut, &byteCountOut)
            if let status = Status.fromRaw(rawStatus)
            {
                self.status =  status
            }
            else
            {
                NSLog("FATAL_ERROR: CCCryptorFinal returned unexpected status (\(rawStatus)).")
                fatalError("CCCryptorUpdate returned unexpected status.")
            }
        }
        return self.status
    }
    /**
        Determines the number of bytes that wil be output by this Cryptor if inputBytes of additional
        data is input.
        
        - parameter inputByteCount: number of bytes that will be input.
        - parameter isFinal: true if buffer to be input will be the last input buffer, false otherwise.
    */
    public func getOutputLength(inputByteCount : Int, isFinal : Bool = false) -> Int
    {
        return CCCryptorGetOutputLength(context.memory, inputByteCount, isFinal)
    }
    
    deinit
    {
        let rawStatus = CCCryptorRelease(context.memory)
        if let status = Status.fromRaw(rawStatus)
        {
            if(status != .Success)
            {
                NSLog("WARNING: CCCryptoRelease failed with status \(rawStatus).")
            }
        }
        else
        {
            NSLog("FATAL_ERROR: CCCryptorUpdate returned unexpected status (\(rawStatus)).")
            fatalError("CCCryptorUpdate returned unexpected status.")
        }
        context.dealloc(1)
    }
    
    private var context = UnsafeMutablePointer<CCCryptorRef>.alloc(1)
    
}
