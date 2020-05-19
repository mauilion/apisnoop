#!/usr/bin/env bb
;; release-stats is a json array of releases and their relevant information
;; where relevant info is:
;; - release version
;; - release date
;; - total Endpoints
;; - total EligibleEndpoints
;; - total StableEndpoints
;; - total Eligible StableEndpoints
;; - conf tested endpoints for each type of Endpoints
;; - tested endpoints for each type of Endpoints


;; RELEASE is a list of Endpoints
(def RELEASE-PATH "data/RELEASE_endpoints.json") ;where RELEASE is 1.x

;; - Endpoint is a map containing info around a k8s endpoint as defined in the openAPISpec

;; - Eligible Endpoints are ones that:
;; - don't deal with Volumes (path does not contain volume)
;; - don't deal with ComponentStatus (kind does not include ComponentStatus)
;; - aren'tusing kubelet for creation or deletion (kind is not like node and action is not delete or post)
;; Our endpoint.json does not have all the info we need to determine ineligibility.
;; We can use the list gathered for v.1.9 though as a temporary solution
(def ineligible-endpoints ["createCoreV1Node"
                           "createStorageV1VolumeAttachment"
                           "deleteCoreV1CollectionNamespacedPersistentVolumeClaim"
                           "deleteCoreV1CollectionPersistentVolume"
                           "deleteCoreV1Node"
                           "deleteStorageV1CollectionVolumeAttachment"
                           "deleteStorageV1VolumeAttachment"
                           "listCoreV1ComponentStatus"
                           "listCoreV1PersistentVolumeClaimForAllNamespaces"
                           "listStorageV1VolumeAttachment"
                           "patchCoreV1NamespacedPersistentVolumeClaim"
                           "patchCoreV1NamespacedPersistentVolumeClaimStatus"
                           "patchCoreV1PersistentVolume"
                           "patchCoreV1PersistentVolumeStatus"
                           "patchStorageV1VolumeAttachment"
                           "patchStorageV1VolumeAttachmentStatus"
                           "readCoreV1ComponentStatus"
                           "readCoreV1NamespacedPersistentVolumeClaimStatus"
                           "readCoreV1PersistentVolumeStatus"
                           "readStorageV1VolumeAttachment"
                           "readStorageV1VolumeAttachmentStatus"
                           "replaceCoreV1NamespacedPersistentVolumeClaimStatus"
                           "replaceCoreV1PersistentVolume"
                           "replaceCoreV1PersistentVolumeStatus"
                           "replaceStorageV1VolumeAttachment"
                           "replaceStorageV1VolumeAttachmentStatus"])
;; String -> Release
(defn slurp-release
  "slurps the json held in our RELEASE-PATH for release"
  [release]
  (json/parse-string (slurp (clojure.string/replace RELEASE-PATH "RELEASE" release))))

;; String -> Boolean
(defn eligible?
  "predicate for whether given operationId matches our eligibility criteria"
  [opID]
  (not (some #{opID} ineligible-endpoints)))

;; Endpoints String -> Boolean
(defn stable?
  "endpoint is in stable level of kubernetes"
  [coll endpoint]
  (let [level (get-in coll [endpoint "level"])]
    (= level "stable")))

;; Endpoints String -> Boolean
(defn conf-tested?
  "endpoint has a positive number of conf hits"
  [coll endpoint]
  (let [conf_hits (get-in coll [endpoint "conformanceHits"])]
    (if conf_hits
      (> conf_hits 0)
      false)))

;; Endpoints String -> Boolean
(defn tested?
  "endpoint has a positive number of conf hits"
  [coll endpoint]
  (let [test_hits (get-in coll [endpoint "testHits"])]
    (if test_hits
      (> test_hits 0)
      false)))

;; ReleaseInfo -> ReleaseStats
(defn generate-stats
  "Given release name and date, generate stats from our release data"
  [[version date]]
  (let [release (slurp-release version)
        endpoints (keys release)
        stable-endpoints (filter #(stable? release %) endpoints)
        eligible-endpoints (filter eligible? endpoints)
        eligible-stable-endpoints (filter eligible? stable-endpoints)]
    {:release version
     :date date
     :endpoints {
                 :total (count endpoints)
                 :stable (count stable-endpoints)
                 :eligible (count eligible-endpoints)
                 :eligibleStable (count eligible-stable-endpoints)}
     :tested {
              :total (count (filter #(tested? release %) endpoints))
              :stable (count (filter #(tested? release %) stable-endpoints))
              :eligible (count (filter #(tested? release %) eligible-endpoints))
              :eligibleStable (count (filter #(tested? release %) eligible-stable-endpoints))}
     :confTested {
                  :total (count (filter #(conf-tested? release %) endpoints))
                  :stable (count (filter #(conf-tested? release %) stable-endpoints))
                  :eligible (count (filter #(conf-tested? release %) eligible-endpoints))
                  :eligibleStable (count (filter #(conf-tested? release %) eligible-stable-endpoints))}}))

(def releases [["1.9"  "2017-12-15"]
               ["1.10" "2018-03-28"]
               ["1.11" "2018-07-03"]
               ["1.12" "2018-09-27"]])

(println (json/generate-string (map generate-stats releases) {:pretty true}))
