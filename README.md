# MIPA 

> **Version:** v1.0.0

This repository contains the MATLAB implementation of the Morphological Image Processing Approach (MIPA) for automatic Atmospheric Boundary Layer Height (ABLH) estimation from LiDAR and ceilometer observations. The algorithm is described and validated in the following publications:
  
[1] Vivone, Gemine, et al. "Atmospheric boundary layer height estimation from aerosol lidar: a new approach based on morphological image processing techniques", Atmospheric Chemistry and Physics, 21, 4249–4265, https://doi.org/10.5194/acp-21-4249-2021, 2021.

[2] D’Amico, Giuseppe, et al. "Atmospheric Boundary Layer Height Estimation from Lidar Observations: Assessment and Validation of MIPA Algorithm." Remote Sensing 17.16 (2025): 2748.

[3] -

## 📄 Full Articles
You can link to the full articles:

[1] https://acp.copernicus.org/articles/21/4249/2021

[2] https://www.mdpi.com/2072-4292/17/16/2748

[3] 

## Bibtex

@article{Vivo_21,
AUTHOR = {Vivone, G. and D'Amico, G. and Summa, D. and Lolli, S. and Amodeo, A. and Bortoli, D. and Pappalardo, G.},
TITLE = {Atmospheric boundary layer height estimation from aerosol lidar: a new approach based on morphological image processing techniques},
JOURNAL = {Atmospheric Chemistry and Physics},
VOLUME = {21},
YEAR = {2021},
NUMBER = {6},
PAGES = {4249--4265},
URL = {https://acp.copernicus.org/articles/21/4249/2021/},
DOI = {10.5194/acp-21-4249-2021}
}

@article{Dami_25,
AUTHOR = {D’Amico, Giuseppe and Arienzo, Alberto and Vivone, Gemine and Amodeo, Aldo and Cardellicchio, Francesco and Gumà-Claramunt, Pilar and De Rosa, Benedetto and Di Girolamo, Paolo and Gandolfi, Ilaria and Giunta, Aldo and Laurita, Teresa and Marra, Fabrizio and Mona, Lucia and Mytilinaios, Michail and Papagiannopoulos, Nikolaos and Rosoldi, Marco and Summa, Donato},
TITLE = {Atmospheric Boundary Layer Height Estimation from Lidar Observations: Assessment and Validation of MIPA Algorithm},
JOURNAL = {Remote Sensing},
VOLUME = {17},
YEAR = {2025},
NUMBER = {16},
ARTICLE-NUMBER = {2748},
URL = {https://www.mdpi.com/2072-4292/17/16/2748},
ISSN = {2072-4292},
DOI = {10.3390/rs17162748}
}

## 📜 License
This code is released under the [CC-BY 4.0](LICENSE).

## Corresponding author  
📌 **[G. D'Amico](https://orcid.org/0000-0002-1584-4631)**

## 🔧 Requirements  

### ✅ MATLAB Version  
- Developed and tested on **MATLAB R2024b**  
- Compatibility with older versions is not guaranteed.  

### 📦 Required Toolboxes  
Ensure you have the following MATLAB toolboxes installed:  
- **[Image Processing Toolbox]** 

## Quick Start

1. Clone or download this repository.

2. Open MATLAB.

3. Ensure that the Image Processing Toolbox is installed.

4. Open the `src` folder and run

```matlab
main_MIPA.m
```

5. In `config_MIPA.m`, set the input file and the measurement type, for example

```matlab
cfg.filename = "demo_lidar";
cfg.measurement_tag = "lidar";
cfg.variable_filename = "input_dataset";
```

6. The retrieved ABLH is written to

```
data/output/Output_demo_lidar.nc
```

The repository includes two demonstration datasets:

- `demo_lidar.nc`
- `demo_chm15k.nc`

For a complete description of the configuration parameters, input/output NetCDF format, and processing workflow, refer to the ATBD.
