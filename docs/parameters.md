

# birneylab/stitchimpute pipeline parameters                                                                                                                
                                                                                                                                                            
A pipeline for imputing genotypes using STITCH, evaluating imputation performance against a ground truth, optimising imputation parameters, and refining the
                                                                                                                                                            
## Input/output options                                                                                                                                     
                                                                                                                                                            
Define where the pipeline should find input data and save output data.                                                                                      
                                                                                                                                                            
| Parameter | Description | Type | Default | Required | Hidden |                                                                                            
|-----------|-----------|-----------|-----------|-----------|-----------|                                                                                   
| `input` | Path to comma-separated file containing information about the samples in the experiment. <details><summary>Help</summary><small>You will need to
| `outdir` | The output directory where the results will be saved. You have to use absolute paths to storage on Cloud infrastructure. | `string` |  | True |
| `email` | Email address for completion summary. <details><summary>Help</summary><small>Set this parameter to your e-mail address to get a summary e-mail w
| `multiqc_title` | MultiQC report title. Printed as page header, used for filename if not otherwise specified. | `string` |  |  |  |                       
                                                                                                                                                            
## Reference genome options                                                                                                                                 
                                                                                                                                                            
Reference genome related files and options required for the workflow.                                                                                       
                                                                                                                                                            
| Parameter | Description | Type | Default | Required | Hidden |                                                                                            
|-----------|-----------|-----------|-----------|-----------|-----------|                                                                                   
| `genome` | Name of iGenomes reference. <details><summary>Help</summary><small>If using a reference genome configured in the pipeline using iGenomes, use t
| `fasta` | Path to FASTA genome file. <details><summary>Help</summary><small>This parameter is *mandatory* if `--genome` is not specified. If you don't hav
| `fasta_fai` | Path to FASTA reference index. <details><summary>Help</summary><small>Currently ignored, the reference index is generated automatically.</sm
| `igenomes_base` | Directory / URL base for iGenomes references. | `string` | s3://ngi-igenomes/igenomes |  | True |                                       
| `igenomes_ignore` | Do not load the iGenomes reference config. <details><summary>Help</summary><small>Do not load `igenomes.config` when running the pipel
                                                                                                                                                            
## Institutional config options                                                                                                                             
                                                                                                                                                            
Parameters used to describe centralised config profiles. These should not be edited.                                                                        
                                                                                                                                                            
| Parameter | Description | Type | Default | Required | Hidden |                                                                                            
|-----------|-----------|-----------|-----------|-----------|-----------|                                                                                   
| `custom_config_version` | Git commit id for Institutional configs. | `string` | master |  | True |                                                        
| `custom_config_base` | Base directory for Institutional configs. <details><summary>Help</summary><small>If you're running offline, Nextflow will not be ab
| `config_profile_name` | Institutional config name. | `string` |  |  | True |                                                                              
| `config_profile_description` | Institutional config description. | `string` |  |  | True |                                                                
| `config_profile_contact` | Institutional config contact information. | `string` |  |  | True |                                                            
| `config_profile_url` | Institutional config URL link. | `string` |  |  | True |                                                                           
                                                                                                                                                            
## Max job request options                                                                                                                                  
                                                                                                                                                            
Set the top limit for requested resources for any single job.                                                                                               
                                                                                                                                                            
| Parameter | Description | Type | Default | Required | Hidden |                                                                                            
|-----------|-----------|-----------|-----------|-----------|-----------|                                                                                   
| `max_cpus` | Maximum number of CPUs that can be requested for any single job. <details><summary>Help</summary><small>Use to set an upper-limit for the CPU
| `max_memory` | Maximum amount of memory that can be requested for any single job. <details><summary>Help</summary><small>Use to set an upper-limit for the
| `max_time` | Maximum amount of time that can be requested for any single job. <details><summary>Help</summary><small>Use to set an upper-limit for the tim
                                                                                                                                                            
## Generic options                                                                                                                                          
                                                                                                                                                            
Less common options for the pipeline, typically set in a config file.                                                                                       
                                                                                                                                                            
| Parameter | Description | Type | Default | Required | Hidden |                                                                                            
|-----------|-----------|-----------|-----------|-----------|-----------|                                                                                   
| `help` | Display help text. | `boolean` | False |  | True |                                                                                               
| `version` | Display version and exit. | `boolean` | False |  | True |                                                                                     
| `publish_dir_mode` | Method used to save pipeline results to output directory. <details><summary>Help</summary><small>The Nextflow `publishDir` option spe
| `email_on_fail` | Email address for completion summary, only when pipeline fails. <details><summary>Help</summary><small>An email address to send a summar
| `plaintext_email` | Send plain-text email instead of HTML. | `boolean` | False |  | True |                                                                
| `max_multiqc_email_size` | File size limit when attaching MultiQC reports to summary emails. | `string` | 25.MB |  | True |                               
| `monochrome_logs` | Do not use coloured log outputs. | `boolean` | False |  | True |                                                                      
| `hook_url` | Incoming hook URL for messaging service <details><summary>Help</summary><small>Incoming hook URL for messaging service. Currently, MS Teams a
| `multiqc_config` | Custom config file to supply to MultiQC. | `string` |  |  | True |                                                                     
| `multiqc_logo` | Custom logo file to supply to MultiQC. File name must also be set in the MultiQC config file | `string` |  |  | True |                   
| `multiqc_methods_description` | Custom MultiQC yaml file containing HTML including a methods description. | `string` |  |  |  |                           
| `validate_params` | Boolean whether to validate parameters against the schema at runtime | `boolean` | True |  | True |                                   
| `validationShowHiddenParams` | Show all params when using `--help` <details><summary>Help</summary><small>By default, parameters set as _hidden_ in the sc
| `validationFailUnrecognisedParams` | Validation of parameters fails when an unrecognised parameter is found. <details><summary>Help</summary><small>By def
| `validationLenientMode` | Validation of parameters in lenient more. <details><summary>Help</summary><small>Allows string values that are parseable as numb
                                                                                                                                                            


