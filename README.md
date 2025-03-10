# RxInferServer.jl

> [!NOTE]  
> This is a work in progress and the API is not yet stable and may undergo significant changes. Use at your own risk.

A Julia package that provides RESTful HTTP server functionality for deploying [RxInfer.jl](https://github.com/biaslab/RxInfer.jl) probabilistic models as web services.

## Installation

```julia
using Pkg
Pkg.add("RxInferServer")
```

## Planned features

- Deploy RxInfer models as HTTP endpoints
- Create multiple instances of the same model
- Run inference, planning and learning in parallel
- Configurable inference parameters (iterations, free energy computation)
- Flexible data input and output formats
- Data layout verification (e.g. missing data, etc.)
- Extensive statistics and diagnostics
- Support for model history and posterior distribution tracking

## License

This project is licensed under the GNU Affero General Public License v3.0 - see the LICENSE file for details.

For companies and organizations that require different licensing terms, commercial licenses are available from [Lazy Dynamics](https://www.lazydynamics.com). Please [contact](mailto:info@lazydynamics.com) Lazy Dynamics for more information about commercial licensing options that may better suit your specific needs and use cases.
