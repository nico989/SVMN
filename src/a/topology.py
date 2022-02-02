from typing import List, Union
from serde import InternalTagging, serde
from serde.yaml import from_yaml


@serde
class ControllerLocal:
    name: str


@serde
class ControllerRemote:
    name: str
    ip: str
    port: int


@serde(tagging=InternalTagging("type"))
class Controllers:
    data: Union[List[ControllerLocal], List[ControllerRemote]]


@serde
class Topology:
    controllers: Controllers


if __name__ == "__main__":
    with open("src/topology.yml") as f:
        yaml = f.read()

    print(f"{from_yaml(Topology, yaml)}")
