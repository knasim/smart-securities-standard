pragma solidity ^0.4.10;

import './interfaces/RegS.sol';
import './interfaces/RegSToken.sol';
import './interfaces/UserChecker.sol';
import './zeppelin-solidity/contracts/ownership/Ownable.sol';

/// @title Implementation of RegS
contract TheRegS is RegS, TransferRestrictor {

  /// Table of AML-KYC checking contracts
  mapping(address => address) amlkycChecker;

  ///
  /// Issuance dates for securities restricted by this contract
  mapping(address => uint256) issuanceDate;

  /// Table of residency status checking contracts
  mapping(address => address) residencyChecker;
  
  ///
  /// Error codes
  enum ErrorCode {
    Ok,
    BuyerAMLKYC,
    BuyerResidency,
    SellerAMLKYC,
    SellerResidency,
    Accreditation
  }

  ///
  /// Register a contract to confirm AML-KYC status
  function registerAmlKycChecker(address _checker, address _token)
    public
  {
    require(Ownable(_token).owner() == msg.sender);
    amlkycChecker[_token] = _checker;
  }

  /// Register residency checker
  function registerResidencyChecker(address _checker, address _token)
    public
  {
    require(Ownable(_token).owner() == msg.sender);
    residencyChecker[_token] = _checker;
  }
  
  ///
  /// Verify rules
  function test(address _from, address _to, uint256 _value, address _token)
    external
    returns (uint16)
  {

    // The seller must have supplied AMLKYC information  
    if (!amlkyc(_from, _token))
      return uint16(ErrorCode.SellerAMLKYC);
    
    // The buyer must have supplied AMLKYC information
    if (!amlkyc(_to, _token))
      return uint16(ErrorCode.BuyerAMLKYC);

    // The seller must be a non-USA investor
    if (!residency(_from, _token))
      return uint16(ErrorCode.SellerResidency);

    // The buyer must be a non-USA investor
    if (!residency(_to, _token))
      return uint16(ErrorCode.BuyerResidency);

    return uint16(ErrorCode.Ok);

  }
  
  ///
  /// Confirm AML-KYC status with the registered checker
  function amlkyc(address _user, address _token)
    internal
    returns (bool)
  {
    return UserChecker(amlkycChecker[_token]).confirm(_user);
  }

  ///
  /// Confirm international status
  function residency(address _user, address _token)
    internal
    returns (bool)
  {
    return UserChecker(residencyChecker[_token]).confirm(_user);
  }

}
