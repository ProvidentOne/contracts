pragma solidity ^0.4.3;

import "./Owned.sol";

contract Manager is Owned {
  mapping (bytes32 => address) private services;
  mapping (bytes32 => address) private persistance;

  function addService(address newService) onlyOwner {
    Managed service = Managed(newService);
    bytes32 h = service.identifier();
    if (services[h] != 0x0) {
      service.destroy();
    }

    services[h] = newService;
  }

  function addPersistance(address newPersistance) onlyOwner {
    Managed db = Managed(newPersistance);
    bytes32 h = db.identifier();
    if (persistance[h] != 0x0) {
      // TODO: Implement persistance migrations
      db.destroy();
    }
    persistance[h] = newPersistance;
  }

  function addressFor(string identifier) constant returns (address) {
    return addressForHash(sha3(identifier));
  }

  function addressForHash(bytes32 h) constant returns (address) {
    if (services[h] != 0x0) {
      return services[h];
    }

    if (persistance[h] != 0x0) {
      return persistance[h];
    }

    throw;
  }
}

contract Managed {
  enum PermissionLevel {
    None,
    Read,
    Write,
    Manager
  }

  mapping (address => PermissionLevel) private permissions;
  address public manager;

  bytes32 public identifier;

  function Managed(string _identifier) {
    permissions[msg.sender] = PermissionLevel.Manager;
    manager = msg.sender;

    identifier = sha3(_identifier);
  }

  function addressFor(string _id) returns (address) {
    return Manager(manager).addressForHash(sha3(_id));
  }


  function destroy() requiresPermission(PermissionLevel.Manager) {
    selfdestruct(manager);
  }


  function transferManagement(address newManager) requiresPermission(PermissionLevel.Manager) {
    manager = newManager;
    permissions[newManager] = PermissionLevel.Manager;
  }

  function assignPermission(address allowed, PermissionLevel level) requiresPermission(PermissionLevel.Manager) {
    permissions[allowed] = level;
  }

  modifier requiresPermission(PermissionLevel requiredPermission) {
    if (uint(permissions[msg.sender]) < uint(requiredPermission)) { throw; }
    else
      _;
  }
}
