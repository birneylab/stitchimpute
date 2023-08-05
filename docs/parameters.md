

# birneylab/stitchimpute pipeline parameters                       
                                                                   
A pipeline for imputing genotypes using STITCH, evaluating imputati
                                                                   
## Input/output options                                            
                                                                   
Define where the pipeline should find input data and save output da
                                                                   
| Parameter | Description | Type | Default | Required | Hidden |   
|-----------|-----------|-----------|-----------|-----------|------
| `input` | Path to comma-separated file containing information abo
| `mode` | Which branch of the pipeline to run | `string` | imputat
| `outdir` | The output directory where the results will be saved. 
| `skip_chr` | Chromosomes to skip <details><summary>Help</summary>
| `grid_search_params` | CSV files containing the values of the K a
| `snp_filtering_criteria` | CSV file containing the threshold for 
| `email` | Email address for completion summary. <details><summary
| `multiqc_title` | MultiQC report title. Printed as page header, u
                                                                   
## Stitch options                                                  
                                                                   
                                                                   
                                                                   
| Parameter | Description | Type | Default | Required | Hidden |   
|-----------|-----------|-----------|-----------|-----------|------
| `stitch_posfile` | Positions to run the imputation over <details>
| `stitch_K` | Number of ancestral haplotypes <details><summary>Hel
| `stitch_nGen` | Number of generations since founding of the popul
                                                                   
## Reference genome options                                        
                                                                   
Reference genome related files and options required for the workflo
                                                                   
| Parameter | Description | Type | Default | Required | Hidden |   
|-----------|-----------|-----------|-----------|-----------|------
| `genome` | Name of iGenomes reference. <details><summary>Help</su
| `fasta` | Path to FASTA genome file. <details><summary>Help</summ
| `igenomes_base` | Directory / URL base for iGenomes references. |
| `igenomes_ignore` | Do not load the iGenomes reference config. <d
                                                                   
## Institutional config options                                    
                                                                   
Parameters used to describe centralised config profiles. These shou
                                                                   
| Parameter | Description | Type | Default | Required | Hidden |   
|-----------|-----------|-----------|-----------|-----------|------
| `custom_config_version` | Git commit id for Institutional configs
| `custom_config_base` | Base directory for Institutional configs. 
| `config_profile_name` | Institutional config name. | `string` |  
| `config_profile_description` | Institutional config description. 
| `config_profile_contact` | Institutional config contact informati
| `config_profile_url` | Institutional config URL link. | `string` 
                                                                   
## Max job request options                                         
                                                                   
Set the top limit for requested resources for any single job.      
                                                                   
| Parameter | Description | Type | Default | Required | Hidden |   
|-----------|-----------|-----------|-----------|-----------|------
| `max_cpus` | Maximum number of CPUs that can be requested for any
| `max_memory` | Maximum amount of memory that can be requested for
| `max_time` | Maximum amount of time that can be requested for any
                                                                   
## Generic options                                                 
                                                                   
Less common options for the pipeline, typically set in a config fil
                                                                   
| Parameter | Description | Type | Default | Required | Hidden |   
|-----------|-----------|-----------|-----------|-----------|------
| `help` | Display help text. | `boolean` |  |  | True |           
| `version` | Display version and exit. | `boolean` |  |  | True | 
| `publish_dir_mode` | Method used to save pipeline results to outp
| `email_on_fail` | Email address for completion summary, only when
| `plaintext_email` | Send plain-text email instead of HTML. | `boo
| `max_multiqc_email_size` | File size limit when attaching MultiQC
| `monochrome_logs` | Do not use coloured log outputs. | `boolean` 
| `hook_url` | Incoming hook URL for messaging service <details><su
| `multiqc_config` | Custom config file to supply to MultiQC. | `st
| `multiqc_logo` | Custom logo file to supply to MultiQC. File name
| `multiqc_methods_description` | Custom MultiQC yaml file containi
| `validate_params` | Boolean whether to validate parameters agains
| `validationShowHiddenParams` | Show all params when using `--help
| `validationFailUnrecognisedParams` | Validation of parameters fai
| `validationLenientMode` | Validation of parameters in lenient mor
                                                                   


