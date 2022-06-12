TAG=LA.UM.9.1.r1-11900.01-SMxxx0.QSSI13.0                                                                        

[[ $1 == "upstream" ]] && {                                                                                                                                                               
git fetch qcacld-3.0 $TAG           
git merge -X subtree=drivers/staging/qcacld-3.0 --signoff FETCH_HEAD                                     
                                                                                                       
git fetch fw-api $TAG           
git merge -X subtree=drivers/staging/fw-api --signoff FETCH_HEAD                                                                                                         

git fetch qca-wifi-host-cmn $TAG           
git merge -X subtree=drivers/staging/qca-wifi-host-cmn --signoff FETCH_HEAD                                                                                                         
                                                                        
git fetch data-kernel $TAG                
git merge -X subtree=techpack/data --signoff FETCH_HEAD                                                                                                                                          
                                                                                                                                                                                                    
git fetch audio-kernel $TAG                  
git merge -X subtree=techpack/audio --signoff FETCH_HEAD                                         
                                                                                                                                                                                                                                                                                           
git fetch https://git.codelinaro.org/clo/la/kernel/msm-4.14 $TAG                                        
git merge --signoff FETCH_HEAD                                                                                                                                                                                                                                                                               
}

[[ $1 == "initial" ]] && {
git remote add qcacld-3.0 https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/qcacld-3.0
git fetch qcacld-3.0 $TAG
git merge -s ours --no-commit --allow-unrelated-histories FETCH_HEAD
git read-tree --prefix=drivers/staging/qcacld-3.0 -u FETCH_HEAD
git commit -s

git remote add fw-api https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/fw-api
git fetch fw-api $TAG
git merge -s ours --no-commit --allow-unrelated-histories FETCH_HEAD
git read-tree --prefix=drivers/staging/fw-api -u FETCH_HEAD
git commit -s

git remote add qca-wifi-host-cmn https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/qca-wifi-host-cmn
git fetch qca-wifi-host-cmn $TAG
git merge -s ours --no-commit --allow-unrelated-histories FETCH_HEAD
git read-tree --prefix=drivers/staging/qca-wifi-host-cmn -u FETCH_HEAD
git commit -s

git remote add data-kernel https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/data-kernel
git fetch data-kernel $TAG
git merge -s ours --no-commit --allow-unrelated-histories FETCH_HEAD
git read-tree --prefix=techpack/data -u FETCH_HEAD
git commit -s

git remote add audio-kernel https://git.codelinaro.org/clo/la/platform/vendor/opensource/audio-kernel
git fetch audio-kernel $TAG
git merge -s ours --no-commit --allow-unrelated-histories FETCH_HEAD
git read-tree --prefix=techpack/audio -u FETCH_HEAD
git commit -s
}
