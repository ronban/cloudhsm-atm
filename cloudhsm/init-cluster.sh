#/bin/sh
CLOUDHSM_HOME=/opt/cloudhsm
HSM_IP=$(aws --region "$AWS_REGION" cloudhsmv2 describe-clusters |jq -r '.Clusters[0].Hsms[].EniIp')
cluster_state=$(aws --region $AWS_REGION cloudhsmv2 describe-clusters --filters clusterIds=$CLUSTER_ID --output text --query 'Clusters[].State')


case $cluster_state in
    
    UNINITIALIZED)
                   echo Initializing $CLUSTER_ID with HSM echo $HSM_IP
                   
                   cd certs
                   FILE=/opt/cloudhsm/certs/"$CLUSTER_ID"_CustomerHsmCertificate.crt
                   if [ ! -f "$FILE" ]; then
                    echo Fetching HSM CSR
                    aws --region $AWS_REGION cloudhsmv2 describe-clusters --filters clusterIds=$CLUSTER_ID \
                                                        --output text \
                                                        --query 'Clusters[].Certificates.ClusterCsr' \
                                                        > "$CLUSTER_ID"_ClusterCsr.csr
                                                        
                    echo Creating new pvk
                    openssl genrsa -aes256 -passout pass:"$PVK_PWD" -out customerCA.key 2048 
                    echo Signing HSM CSR
                    openssl req -new -x509 \
                            -key customerCA.key \
                            -days 3652 \
                            -passin pass:"$PVK_PWD" \
                            -out customerCA.crt \
                            -subj "$CERT_CNAME"
                        
                        
                    openssl x509 -req -days 3652 -in "$CLUSTER_ID"_ClusterCsr.csr \
                                -CA customerCA.crt \
                                -CAkey customerCA.key \
                                -passin pass:"$PVK_PWD" \
                                -CAcreateserial \
                                -out "$CLUSTER_ID"_CustomerHsmCertificate.crt
                   fi

                   echo Uploading signed HSM CSR
                   aws --region $AWS_REGION cloudhsmv2 initialize-cluster --cluster-id "$CLUSTER_ID" \
                                                        --signed-cert file://"$CLUSTER_ID"_CustomerHsmCertificate.crt \
                                                        --trust-anchor file://customerCA.crt
                    ;;

    INITIALIZED) 
        echo Activating
        /opt/cloudhsm/bin/configure -a $HSM_IP
        /bin/bash
        ;;


    INITIALIZING) 
        echo "Wait until over"
        ;;

    ACTIVE) 
        echo "All done"
        ;;

    *) 
        echo "Unknown state"
        ;;

esac






