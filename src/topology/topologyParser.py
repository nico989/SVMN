from email.policy import default
import ipaddress
import enum
from typing import List, Optional, Union
from serde import InternalTagging, field, serde
from serde.yaml import from_yaml
from serde.json import from_json


@serde
class Network:
    autoMac: bool = field(default=False)
    autoArp: bool = field(default=False)


@serde
class ControllerLocal:
    name: str


@serde
class ControllerRemote:
    name: str
    ip: ipaddress.IPv4Address
    port: int


@serde
class NetworkLink:
    node: str
    bandwidth: Optional[int]
    delay: Optional[str]
    fromInterface: Optional[str]
    toInterface: Optional[str]


@serde
class Switch:
    name: str
    links: List[NetworkLink] = field(default_factory=list)


@serde
class Container:
    name: str
    image: str
    cmd: Optional[str]
    wait: Optional[bool]


@serde
class NetworkInterface:
    name: str
    ip: ipaddress.IPv4Interface
    mac: Optional[str]


@serde
class Host:
    name: str
    ip: ipaddress.IPv4Interface
    mac: Optional[str]
    image: Optional[str]
    containers: List[Container] = field(default_factory=list)
    interfaces: List[NetworkInterface] = field(default_factory=list)


@serde(tagging=InternalTagging("type"))
class Topology:
    network: Network
    controllers: List[Union[ControllerLocal, ControllerRemote]]
    switches: List[Switch]
    hosts: List[Host]


class Format(enum.Enum):
    YAML = enum.auto()
    JSON = enum.auto()


def parseTopology(topology: str, format: Format) -> Topology:
    if format is Format.YAML:
        return from_yaml(Topology, topology)
    elif format is Format.JSON:
        return from_json(Topology, topology)
    else:
        raise ValueError(f"Unknown format {format}")
