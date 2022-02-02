import ipaddress
import enum
from typing import List, Optional, Union
from serde import InternalTagging, serde
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
class SwitchLink:
    node: str
    bandwidth: Optional[int]
    delay: Optional[str]


@serde
class Switch:
    name: str
    links: List[SwitchLink]


@serde
class Host:
    name: str
    ip: ipaddress.IPv4Interface
    image: str


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
