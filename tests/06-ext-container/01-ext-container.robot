*** Settings ***
Library           OperatingSystem
Library           Process
Resource          ../common.robot
Suite Setup       Setup
Suite Teardown    Run Keyword    Cleanup

*** Variables ***
${lab-name}       06-ext-container
${lab-file-name}  01-ext-container.clab.yml
${runtime}        docker

*** Test Cases ***
Start ext-containers
    Run     sudo ${runtime} run --name ext1 --label clab-node-name=ext1 --rm -d --cap-add NET_ADMIN alpine sleep infinity
    Run     sudo ${runtime} run --name ext2 --label clab-node-name=ext2 --rm -d --cap-add NET_ADMIN alpine sleep infinity

Deploy ${lab-name} lab
    Skip If    '${runtime}' == 'containerd'
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    sudo -E ${CLAB_BIN} --runtime ${runtime} deploy -t ${CURDIR}/${lab-file-name}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Verify links in node ext1
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    sudo ${CLAB_BIN} --runtime ${runtime} exec -t ${CURDIR}/${lab-file-name} --label clab-node-name\=ext1 --cmd "ip link show dev eth1"
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${output}    state UP

Verify ip and thereby exec on ext1
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    sudo ${CLAB_BIN} --runtime ${runtime} exec -t ${CURDIR}/${lab-file-name} --label clab-node-name\=ext1 --cmd "ip address show dev eth1"
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${output}    192.168.0.1/24

Verify links in node ext2
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    sudo ${CLAB_BIN} --runtime ${runtime} exec -t ${CURDIR}/${lab-file-name} --label clab-node-name\=ext2 --cmd "ip link show dev eth1"
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${output}    state UP

Verify ip and thereby exec on ext2
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    sudo ${CLAB_BIN} --runtime ${runtime} exec -t ${CURDIR}/${lab-file-name} --label clab-node-name\=ext2 --cmd "ip address show dev eth1"
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${output}    192.168.0.2/24

Verify ping from ext1 to ext2 on eth1
    ${result} =    Run Process
    ...    ${runtime} exec ext1 ping -w 2 -c 2 192.168.0.2       shell=True
    Log    ${result.stderr}
    Log    ${result.stdout}
    Should Be Equal As Integers    ${result.rc}    0
    Should Contain  ${result.stdout}    0% packet loss

*** Keywords ***
Setup
    # skipping this test suite for non docker runtimes
    Skip If    '${runtime}' != 'docker'

Cleanup
    Run    sudo ${CLAB_BIN} --runtime ${runtime} destroy -t ${CURDIR}/${lab-file-name} --cleanup
    Run    ${runtime} rm -f ext1
    Run    ${runtime} rm -f ext2
