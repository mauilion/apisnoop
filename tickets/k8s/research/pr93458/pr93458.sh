echo 
date
echo 

cd ~/go/src/k8s.io/kubernetes

TEST_NAME='should run the lifecycle of a Deployment'
echo $TEST_NAME

# Need to escape the Test description
# Here we are escaping the [] and replacing each space with a .
# [ => \[
# ] => \]
# :space: => .
FOCUS=$(echo "$TEST_NAME" \
  | sed "s/\[/\\\[/g" \
  | sed "s/\]/\\\]/g" \
  | sed "s/[[:space:]]/\./g")

# Run Test!
go test ./test/e2e/ -v -timeout=0 -kubeconfig=$HOME/.kube/config --report-dir=/tmp/ARTIFACTS -ginkgo.focus=$FOCUS -ginkgo.noColor

cd -
