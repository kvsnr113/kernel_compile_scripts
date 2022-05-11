TAG="LA.UM.9.1.r1-11900-SMxxx0.0"                                                                        
                                                                                                         
upstream (){                                                                                             
        git fetch https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/$1 $2           
        git merge -X subtree=drivers/staging/$1 --signoff FETCH_HEAD                                     
}                                                                                                        
                                                                                                         
upstream2 (){                                                                                            
        git fetch https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/$1 $2                
        git merge -X subtree=techpack/data --signoff FETCH_HEAD                                          
}                                                                                                        
                                                                                                         
upstream3 (){                                                                                            
        git fetch https://git.codelinaro.org/clo/la/platform/vendor/opensource/$1 $2                     
        git merge -X subtree=techpack/audio --signoff FETCH_HEAD                                         
}                                                                                                        
                                                                                                         
upstream4 (){                                                                                            
        git fetch https://git.codelinaro.org/clo/la/kernel/$1 $2                                         
        git merge --signoff FETCH_HEAD                                                                   
}                                                                                                        
                                                                                                         
upstream qcacld-3.0 $TAG && \                                                                            
upstream fw-api $TAG && \                                                                                
upstream qca-wifi-host-cmn $TAG && \                                                                     
upstream2 data-kernel $TAG && \                                                                          
upstream3 audio-kernel $TAG && \                                                                         
upstream4 msm-4.14 $TAG
