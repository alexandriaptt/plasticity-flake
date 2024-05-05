# Description

A Nix flake for the [Plasticity CAD modeling software](https://github.com/nkallen/plasticity)

The website can be found [here](https://www.plasticity.xyz/).

Funding for this project was provided by ExoBody Systems Inc.


---

# Usage

Standalone execution:

`nix run github:alexandriaptt/plasticity-flake`

Integration into system flake:

```nix
{
  # Add to Flake Inputs
  inputs = {
    plasticity.url = "github:alexandriaptt/plasticity-flake";
    . . .
  }

  outputs = { ... } @ inputs {
    # Add package to system
    environment.systemPackages = [ inputs.plasticity.packages.${system}. ];
  }
}


```