import ipaddress
import enum
from typing import List, Optional, Union
from serde import InternalTagging, field, serde
from serde.yaml import from_yaml
from serde.json import from_json


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
class NetworkInterface:
    name: str
    ip: ipaddress.IPv4Interface


@serde
class Host:
    name: str
    ip: ipaddress.IPv4Interface
    mac: Optional[EUI48] = field(
        serializer=lambda x: x and str(x), deserializer=lambda x: x and EUI48(x)
    )
    image: str
    interfaces: List[NetworkInterface] = field(default_factory=list)


@serde(tagging=InternalTagging("type"))
class Topology:
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
