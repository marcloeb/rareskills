object "Example" {
  code {
    
    datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
    return(0, datasize("Runtime"))
  }
  object "Runtime" {
    // Return the calldata
    code {
      let a := iszero(2)
      
      mstore(0x80, calldataload(0))
      return(0x80, calldatasize())
    }
  }
}