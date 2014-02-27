#!/bin/bash

# Test interop with OpenSSL for each common ciphersuite and version.
# Also test selfop for ciphersuites not shared with OpenSSL.

let "tests = 0"
let "failed = 0"
let "skipped = 0"

# default values, can be overriden by the environment
: ${P_SRV:=../programs/ssl/ssl_server2}
: ${P_CLI:=../programs/ssl/ssl_client2}
: ${OPENSSL:=openssl}

MODES="ssl3 tls1 tls1_1 tls1_2"
VERIFIES="NO YES"
TYPES="ECDSA RSA PSK"
FILTER=""
VERBOSE=""

print_usage() {
    echo "Usage: $0"
    echo -e "  -f|--filter\tFilter ciphersuites to test (Default: all)"
    echo -e "  -h|--help\t\tPrint this help."
    echo -e "  -m|--modes\tWhich modes to perform (Default: \"ssl3 tls1 tls1_1 tls1_2\")"
    echo -e "  -t|--types\tWhich key exchange type to perform (Default: \"ECDSA RSA PSK\")"
    echo -e "  -V|--verify\tWhich verification modes to perform (Default: \"NO YES\")"
    echo -e "  -v|--verbose\t\tSet verbose output."
}

get_options() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -f|--filter)
                shift; FILTER=$1
                ;;
            -m|--modes)
                shift; MODES=$1
                ;;
            -t|--types)
                shift; TYPES=$1
                ;;
            -V|--verify)
                shift; VERIFIES=$1
                ;;
            -v|--verbose)
                VERBOSE=1
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                echo "Unknown argument: '$1'"
                print_usage
                exit 1
                ;;
        esac
        shift
    done
}

log() {
  if [ "X" != "X$VERBOSE" ]; then
    echo "$@"
  fi
}

filter()
{
  LIST=$1
  FILTER=$2

  NEW_LIST=""

  for i in $LIST;
  do
    NEW_LIST="$NEW_LIST $( echo "$i" | grep "$FILTER" )"
  done

  # normalize whitespace
  echo "$NEW_LIST" | sed -e 's/[[:space:]]\+/ /g' -e 's/^ //' -e 's/ $//'
}

setup_ciphersuites()
{
    P_CIPHERS=""
    O_CIPHERS=""

    case $TYPE in

        "ECDSA")
            if [ "$MODE" != "ssl3" ];
            then
                P_CIPHERS="$P_CIPHERS                       \
                    TLS-ECDHE-ECDSA-WITH-NULL-SHA           \
                    TLS-ECDHE-ECDSA-WITH-RC4-128-SHA        \
                    TLS-ECDHE-ECDSA-WITH-3DES-EDE-CBC-SHA   \
                    TLS-ECDHE-ECDSA-WITH-AES-128-CBC-SHA    \
                    TLS-ECDHE-ECDSA-WITH-AES-256-CBC-SHA    \
                    TLS-ECDH-ECDSA-WITH-NULL-SHA            \
                    TLS-ECDH-ECDSA-WITH-RC4-128-SHA         \
                    TLS-ECDH-ECDSA-WITH-3DES-EDE-CBC-SHA    \
                    TLS-ECDH-ECDSA-WITH-AES-128-CBC-SHA     \
                    TLS-ECDH-ECDSA-WITH-AES-256-CBC-SHA     \
                    "
                O_CIPHERS="$O_CIPHERS               \
                    ECDHE-ECDSA-NULL-SHA            \
                    ECDHE-ECDSA-RC4-SHA             \
                    ECDHE-ECDSA-DES-CBC3-SHA        \
                    ECDHE-ECDSA-AES128-SHA          \
                    ECDHE-ECDSA-AES256-SHA          \
                    ECDH-ECDSA-NULL-SHA             \
                    ECDH-ECDSA-RC4-SHA              \
                    ECDH-ECDSA-DES-CBC3-SHA         \
                    ECDH-ECDSA-AES128-SHA           \
                    ECDH-ECDSA-AES256-SHA           \
                    "
            fi
            if [ "$MODE" = "tls1_2" ];
            then
                P_CIPHERS="$P_CIPHERS                               \
                    TLS-ECDHE-ECDSA-WITH-AES-128-CBC-SHA256         \
                    TLS-ECDHE-ECDSA-WITH-AES-256-CBC-SHA384         \
                    TLS-ECDHE-ECDSA-WITH-AES-128-GCM-SHA256         \
                    TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384         \
                    TLS-ECDH-ECDSA-WITH-AES-128-CBC-SHA256          \
                    TLS-ECDH-ECDSA-WITH-AES-256-CBC-SHA384          \
                    TLS-ECDH-ECDSA-WITH-AES-128-GCM-SHA256          \
                    TLS-ECDH-ECDSA-WITH-AES-256-GCM-SHA384          \
                    "
                O_CIPHERS="$O_CIPHERS               \
                    ECDHE-ECDSA-AES128-SHA256       \
                    ECDHE-ECDSA-AES256-SHA384       \
                    ECDHE-ECDSA-AES128-GCM-SHA256   \
                    ECDHE-ECDSA-AES256-GCM-SHA384   \
                    ECDH-ECDSA-AES128-SHA256        \
                    ECDH-ECDSA-AES256-SHA384        \
                    ECDH-ECDSA-AES128-GCM-SHA256    \
                    ECDH-ECDSA-AES256-GCM-SHA384    \
                    "
            fi
            ;;

        "RSA")
            P_CIPHERS="$P_CIPHERS                       \
                TLS-DHE-RSA-WITH-AES-128-CBC-SHA        \
                TLS-DHE-RSA-WITH-AES-256-CBC-SHA        \
                TLS-DHE-RSA-WITH-CAMELLIA-128-CBC-SHA   \
                TLS-DHE-RSA-WITH-CAMELLIA-256-CBC-SHA   \
                TLS-DHE-RSA-WITH-3DES-EDE-CBC-SHA       \
                TLS-RSA-WITH-AES-256-CBC-SHA            \
                TLS-RSA-WITH-CAMELLIA-256-CBC-SHA       \
                TLS-RSA-WITH-AES-128-CBC-SHA            \
                TLS-RSA-WITH-CAMELLIA-128-CBC-SHA       \
                TLS-RSA-WITH-3DES-EDE-CBC-SHA           \
                TLS-RSA-WITH-RC4-128-SHA                \
                TLS-RSA-WITH-RC4-128-MD5                \
                TLS-RSA-WITH-NULL-MD5                   \
                TLS-RSA-WITH-NULL-SHA                   \
                TLS-RSA-WITH-DES-CBC-SHA                \
                TLS-DHE-RSA-WITH-DES-CBC-SHA            \
                "
            O_CIPHERS="$O_CIPHERS               \
                DHE-RSA-AES128-SHA              \
                DHE-RSA-AES256-SHA              \
                DHE-RSA-CAMELLIA128-SHA         \
                DHE-RSA-CAMELLIA256-SHA         \
                EDH-RSA-DES-CBC3-SHA            \
                AES256-SHA                      \
                CAMELLIA256-SHA                 \
                AES128-SHA                      \
                CAMELLIA128-SHA                 \
                DES-CBC3-SHA                    \
                RC4-SHA                         \
                RC4-MD5                         \
                NULL-MD5                        \
                NULL-SHA                        \
                DES-CBC-SHA                     \
                EDH-RSA-DES-CBC-SHA             \
                "
            if [ "$MODE" != "ssl3" ];
            then
                P_CIPHERS="$P_CIPHERS                       \
                    TLS-ECDHE-RSA-WITH-AES-128-CBC-SHA      \
                    TLS-ECDHE-RSA-WITH-AES-256-CBC-SHA      \
                    TLS-ECDHE-RSA-WITH-3DES-EDE-CBC-SHA     \
                    TLS-ECDHE-RSA-WITH-RC4-128-SHA          \
                    TLS-ECDHE-RSA-WITH-NULL-SHA             \
                    "
                O_CIPHERS="$O_CIPHERS               \
                    ECDHE-RSA-AES256-SHA            \
                    ECDHE-RSA-AES128-SHA            \
                    ECDHE-RSA-DES-CBC3-SHA          \
                    ECDHE-RSA-RC4-SHA               \
                    ECDHE-RSA-NULL-SHA              \
                    "
            fi
            if [ "$MODE" = "tls1_2" ];
            then
                P_CIPHERS="$P_CIPHERS                       \
                    TLS-RSA-WITH-NULL-SHA256                \
                    TLS-RSA-WITH-AES-128-CBC-SHA256         \
                    TLS-DHE-RSA-WITH-AES-128-CBC-SHA256     \
                    TLS-RSA-WITH-AES-256-CBC-SHA256         \
                    TLS-DHE-RSA-WITH-AES-256-CBC-SHA256     \
                    TLS-ECDHE-RSA-WITH-AES-128-CBC-SHA256   \
                    TLS-ECDHE-RSA-WITH-AES-256-CBC-SHA384   \
                    TLS-RSA-WITH-AES-128-GCM-SHA256         \
                    TLS-RSA-WITH-AES-256-GCM-SHA384         \
                    TLS-DHE-RSA-WITH-AES-128-GCM-SHA256     \
                    TLS-DHE-RSA-WITH-AES-256-GCM-SHA384     \
                    TLS-ECDHE-RSA-WITH-AES-128-GCM-SHA256   \
                    TLS-ECDHE-RSA-WITH-AES-256-GCM-SHA384   \
                    "
                O_CIPHERS="$O_CIPHERS           \
                    NULL-SHA256                 \
                    AES128-SHA256               \
                    DHE-RSA-AES128-SHA256       \
                    AES256-SHA256               \
                    DHE-RSA-AES256-SHA256       \
                    ECDHE-RSA-AES128-SHA256     \
                    ECDHE-RSA-AES256-SHA384     \
                    AES128-GCM-SHA256           \
                    DHE-RSA-AES128-GCM-SHA256   \
                    AES256-GCM-SHA384           \
                    DHE-RSA-AES256-GCM-SHA384   \
                    ECDHE-RSA-AES128-GCM-SHA256 \
                    ECDHE-RSA-AES256-GCM-SHA384 \
                    "
            fi
            ;;

        "PSK")
            P_CIPHERS="$P_CIPHERS                       \
                TLS-PSK-WITH-RC4-128-SHA                \
                TLS-PSK-WITH-3DES-EDE-CBC-SHA           \
                TLS-PSK-WITH-AES-128-CBC-SHA            \
                TLS-PSK-WITH-AES-256-CBC-SHA            \
                "
            O_CIPHERS="$O_CIPHERS               \
                PSK-RC4-SHA                     \
                PSK-3DES-EDE-CBC-SHA            \
                PSK-AES128-CBC-SHA              \
                PSK-AES256-CBC-SHA              \
                "
            ;;
    esac

    # Filter ciphersuites
    if [ "X" != "X$FILTER" ];
    then
        O_CIPHERS=$( filter "$O_CIPHERS" "$FILTER" )
        P_CIPHERS=$( filter "$P_CIPHERS" "$FILTER" )
    fi

}

add_polarssl_ciphersuites()
{
    ADD_CIPHERS=""

    case $TYPE in

        "ECDSA")
            if [ "$MODE" != "ssl3" ];
            then
                ADD_CIPHERS="$ADD_CIPHERS                           \
                    TLS-ECDHE-ECDSA-WITH-CAMELLIA-128-CBC-SHA256    \
                    TLS-ECDHE-ECDSA-WITH-CAMELLIA-256-CBC-SHA384    \
                    TLS-ECDH-ECDSA-WITH-CAMELLIA-128-CBC-SHA256     \
                    TLS-ECDH-ECDSA-WITH-CAMELLIA-256-CBC-SHA384     \
                    "
            fi
            if [ "$MODE" = "tls1_2" ];
            then
                ADD_CIPHERS="$ADD_CIPHERS                           \
                    TLS-ECDHE-ECDSA-WITH-CAMELLIA-128-GCM-SHA256    \
                    TLS-ECDHE-ECDSA-WITH-CAMELLIA-256-GCM-SHA384    \
                    TLS-ECDH-ECDSA-WITH-CAMELLIA-128-GCM-SHA256     \
                    TLS-ECDH-ECDSA-WITH-CAMELLIA-256-GCM-SHA384     \
                    "
            fi
            ;;

        "RSA")
            if [ "$MODE" != "ssl3" ];
            then
                ADD_CIPHERS="$ADD_CIPHERS                       \
                    TLS-ECDHE-RSA-WITH-CAMELLIA-128-CBC-SHA256  \
                    TLS-ECDHE-RSA-WITH-CAMELLIA-256-CBC-SHA384  \
                    "
            fi
            if [ "$MODE" = "tls1_2" ];
            then
                ADD_CIPHERS="$ADD_CIPHERS                       \
                    TLS-RSA-WITH-CAMELLIA-128-CBC-SHA256        \
                    TLS-RSA-WITH-CAMELLIA-256-CBC-SHA256        \
                    TLS-DHE-RSA-WITH-CAMELLIA-128-CBC-SHA256    \
                    TLS-DHE-RSA-WITH-CAMELLIA-256-CBC-SHA256    \
                    TLS-ECDHE-RSA-WITH-CAMELLIA-128-GCM-SHA256  \
                    TLS-ECDHE-RSA-WITH-CAMELLIA-256-GCM-SHA384  \
                    TLS-DHE-RSA-WITH-CAMELLIA-128-GCM-SHA256    \
                    TLS-DHE-RSA-WITH-CAMELLIA-256-GCM-SHA384    \
                    TLS-RSA-WITH-CAMELLIA-128-GCM-SHA256        \
                    TLS-RSA-WITH-CAMELLIA-256-GCM-SHA384        \
                    "
            fi
            ;;

        "PSK")
            ADD_CIPHERS="$ADD_CIPHERS                    \
                TLS-DHE-PSK-WITH-RC4-128-SHA             \
                TLS-DHE-PSK-WITH-3DES-EDE-CBC-SHA        \
                TLS-DHE-PSK-WITH-AES-128-CBC-SHA         \
                TLS-DHE-PSK-WITH-AES-256-CBC-SHA         \
                TLS-DHE-PSK-WITH-NULL-SHA                \
                TLS-PSK-WITH-NULL-SHA                    \
                TLS-RSA-PSK-WITH-RC4-128-SHA             \
                TLS-RSA-PSK-WITH-3DES-EDE-CBC-SHA        \
                TLS-RSA-PSK-WITH-AES-256-CBC-SHA         \
                TLS-RSA-PSK-WITH-AES-128-CBC-SHA         \
                TLS-RSA-WITH-NULL-SHA                    \
                TLS-RSA-WITH-NULL-MD5                    \
                TLS-PSK-WITH-AES-128-CBC-SHA256          \
                TLS-PSK-WITH-AES-256-CBC-SHA384          \
                TLS-DHE-PSK-WITH-AES-128-CBC-SHA256      \
                TLS-DHE-PSK-WITH-AES-256-CBC-SHA384      \
                TLS-PSK-WITH-NULL-SHA256                 \
                TLS-PSK-WITH-NULL-SHA384                 \
                TLS-DHE-PSK-WITH-NULL-SHA256             \
                TLS-DHE-PSK-WITH-NULL-SHA384             \
                TLS-RSA-PSK-WITH-AES-256-CBC-SHA384      \
                TLS-RSA-PSK-WITH-AES-128-CBC-SHA256      \
                TLS-RSA-PSK-WITH-NULL-SHA256             \
                TLS-RSA-PSK-WITH-NULL-SHA384             \
                TLS-DHE-PSK-WITH-CAMELLIA-128-CBC-SHA256 \
                TLS-DHE-PSK-WITH-CAMELLIA-256-CBC-SHA384 \
                TLS-PSK-WITH-CAMELLIA-128-CBC-SHA256     \
                TLS-PSK-WITH-CAMELLIA-256-CBC-SHA384     \
                TLS-RSA-PSK-WITH-CAMELLIA-256-CBC-SHA384 \
                TLS-RSA-PSK-WITH-CAMELLIA-128-CBC-SHA256 \
                "
            if [ "$MODE" != "ssl3" ];
            then
                ADD_CIPHERS="$ADD_CIPHERS                       \
                    TLS-ECDHE-PSK-WITH-AES-256-CBC-SHA          \
                    TLS-ECDHE-PSK-WITH-AES-128-CBC-SHA          \
                    TLS-ECDHE-PSK-WITH-3DES-EDE-CBC-SHA         \
                    TLS-ECDHE-PSK-WITH-RC4-128-SHA              \
                    TLS-ECDHE-PSK-WITH-NULL-SHA                 \
                    TLS-ECDHE-PSK-WITH-AES-256-CBC-SHA384       \
                    TLS-ECDHE-PSK-WITH-CAMELLIA-256-CBC-SHA384  \
                    TLS-ECDHE-PSK-WITH-AES-128-CBC-SHA256       \
                    TLS-ECDHE-PSK-WITH-CAMELLIA-128-CBC-SHA256  \
                    TLS-ECDHE-PSK-WITH-NULL-SHA384              \
                    TLS-ECDHE-PSK-WITH-NULL-SHA256              \
                    "
            fi
            if [ "$MODE" = "tls1_2" ];
            then
                ADD_CIPHERS="$ADD_CIPHERS                       \
                    TLS-PSK-WITH-AES-128-GCM-SHA256             \
                    TLS-PSK-WITH-AES-256-GCM-SHA384             \
                    TLS-DHE-PSK-WITH-AES-128-GCM-SHA256         \
                    TLS-DHE-PSK-WITH-AES-256-GCM-SHA384         \
                    TLS-RSA-PSK-WITH-CAMELLIA-128-GCM-SHA256    \
                    TLS-RSA-PSK-WITH-CAMELLIA-256-GCM-SHA384    \
                    TLS-PSK-WITH-CAMELLIA-128-GCM-SHA256        \
                    TLS-PSK-WITH-CAMELLIA-256-GCM-SHA384        \
                    TLS-DHE-PSK-WITH-CAMELLIA-128-GCM-SHA256    \
                    TLS-DHE-PSK-WITH-CAMELLIA-256-GCM-SHA384    \
                    TLS-RSA-PSK-WITH-AES-256-GCM-SHA384         \
                    TLS-RSA-PSK-WITH-AES-128-GCM-SHA256         \
                    TLS-RSA-WITH-NULL-SHA256                    \
                    "
            fi
            ;;
    esac

    # Filter new ciphersuites and add them
    if [ "X" != "X$FILTER" ]; then
        ADD_CIPHERS=$( filter "$ADD_CIPHERS" "$FILTER" )
    fi
    # avoid P_CIPHERS being only ' '
    if [ "X" != "X$P_CIPHERS" ]; then
        P_CIPHERS="$P_CIPHERS $ADD_CIPHERS"
    else
        P_CIPHERS="$ADD_CIPHERS"
    fi
}

setup_arguments()
{
    # avoid an avalanche of errors due to typos
    case $MODE in
        ssl3|tls1|tls1_1|tls1_2)
            ;;
        *)
            echo "error: invalid mode: $MODE" >&2
            exit 1;
    esac

    P_SERVER_ARGS="server_addr=0.0.0.0 force_version=$MODE"
    P_CLIENT_ARGS="server_name=localhost force_version=$MODE"
    O_SERVER_ARGS="-www -quiet -cipher NULL,ALL -$MODE"
    O_CLIENT_ARGS="-$MODE"

    if [ "X$VERIFY" = "XYES" ];
    then
        P_SERVER_ARGS="$P_SERVER_ARGS ca_file=data_files/test-ca_cat12.crt auth_mode=required"
        P_CLIENT_ARGS="$P_CLIENT_ARGS ca_file=data_files/test-ca_cat12.crt auth_mode=required"
        O_SERVER_ARGS="$O_SERVER_ARGS -CAfile data_files/test-ca_cat12.crt -Verify 10"
        O_CLIENT_ARGS="$O_CLIENT_ARGS -CAfile data_files/test-ca_cat12.crt -verify 10"
    else
        # ssl_server2 defaults to optional, but we want to test handshakes
        # that don't exchange client certificate at all too
        P_SERVER_ARGS="$P_SERVER_ARGS ca_file=data_files/test-ca_cat12.crt auth_mode=none"
    fi

    case $TYPE in
        "ECDSA")
            P_SERVER_ARGS="$P_SERVER_ARGS crt_file=data_files/server5.crt key_file=data_files/server5.key"
            P_CLIENT_ARGS="$P_CLIENT_ARGS crt_file=data_files/server6.crt key_file=data_files/server6.key"
            O_SERVER_ARGS="$O_SERVER_ARGS -cert data_files/server5.crt -key data_files/server5.key"
            O_CLIENT_ARGS="$O_CLIENT_ARGS -cert data_files/server6.crt -key data_files/server6.key"
            ;;

        "RSA")
            P_SERVER_ARGS="$P_SERVER_ARGS crt_file=data_files/server2.crt key_file=data_files/server2.key"
            P_CLIENT_ARGS="$P_CLIENT_ARGS crt_file=data_files/server1.crt key_file=data_files/server1.key"
            O_SERVER_ARGS="$O_SERVER_ARGS -cert data_files/server2.crt -key data_files/server2.key"
            O_CLIENT_ARGS="$O_CLIENT_ARGS -cert data_files/server1.crt -key data_files/server1.key"
            ;;

        "PSK")
            P_SERVER_ARGS="$P_SERVER_ARGS psk=6162636465666768696a6b6c6d6e6f70"
            P_CLIENT_ARGS="$P_CLIENT_ARGS psk=6162636465666768696a6b6c6d6e6f70"
            # openssl s_server won't start without certificates...
            O_SERVER_ARGS="$O_SERVER_ARGS -psk 6162636465666768696a6b6c6d6e6f70 -cert data_files/server1.crt -key data_files/server1.key"
            O_CLIENT_ARGS="$O_CLIENT_ARGS -psk 6162636465666768696a6b6c6d6e6f70"
            ;;
    esac
}

# start_server <name>
# also saves name and command
start_server() {
    case $1 in
        [Oo]pen*)
            SERVER_CMD="$OPENSSL s_server $O_SERVER_ARGS"
            ;;
        [Pp]olar*)
            SERVER_CMD="$P_SRV $P_SERVER_ARGS"
            ;;
        *)
            echo "error: invalid server name: $1" >&2
            exit 1
            ;;
    esac
    SERVER_NAME=$1

    log "$SERVER_CMD"
    $SERVER_CMD >srv_out 2>&1 &
    PROCESS_ID=$!

    sleep 1
}

# terminate the running server (closing it cleanly if it is ours)
stop_server() {
    case $SERVER_NAME in
        [Pp]olar*)
            # we must force a PSK suite when in PSK mode (otherwise client
            # auth will fail), so use $O_CIPHERS
            CS=$( echo "$O_CIPHERS" | tr ' ' ':' )
            echo SERVERQUIT | \
                $OPENSSL s_client $O_CLIENT_ARGS -cipher "$CS" >/dev/null 2>&1
            ;;
        *)
            kill $PROCESS_ID 2>/dev/null
    esac

    wait $PROCESS_ID 2>/dev/null
    rm -f srv_out
}

# kill the running server (used when killed by signal)
cleanup() {
    rm -f srv_out cli_out
    kill $PROCESS_ID
    exit 1
}

# run_client <name> <cipher>
run_client() {
    # announce what we're going to do
    let "tests++"
    VERIF=$(echo $VERIFY | tr '[:upper:]' '[:lower:]')
    TITLE="${1:0:1}->${SERVER_NAME:0:1} $MODE,$VERIF $2 "
    echo -n "$TITLE"
    LEN=`echo "$TITLE" | wc -c`
    LEN=`echo 72 - $LEN | bc`
    for i in `seq 1 $LEN`; do echo -n '.'; done; echo -n ' '

    # run the command and interpret result
    case $1 in
        [Oo]pen*)
            CLIENT_CMD="$OPENSSL s_client $O_CLIENT_ARGS -cipher $2"
            log "$CLIENT_CMD"
            ( echo -e 'GET HTTP/1.0'; echo; ) | $CLIENT_CMD > cli_out 2>&1
            EXIT=$?

            if [ "$EXIT" == "0" ]; then
                RESULT=0
            else
                if grep 'Cipher is (NONE)' cli_out >/dev/null; then
                    RESULT=1
                else
                    RESULT=2
                fi
            fi
            ;;

        [Pp]olar*)
            CLIENT_CMD="$P_CLI $P_CLIENT_ARGS force_ciphersuite=$2"
            log "$CLIENT_CMD"
            $CLIENT_CMD > cli_out
            EXIT=$?

            case $EXIT in
                "0")    RESULT=0    ;;
                "2")    RESULT=1    ;;
                *)      RESULT=2    ;;
            esac
            ;;

        *)
            echo "error: invalid client name: $1" >&2
            exit 1
            ;;
    esac

    # report and count result
    case $RESULT in
        "0")
            echo PASS
            ;;
        "1")
            echo SKIP
            let "skipped++"
            ;;
        "2")
            echo FAIL
            echo "  ! $SERVER_CMD"
            echo "  ! $CLIENT_CMD"
            echo -n "  ! ... "
            tail -n1 cli_out
            let "failed++"
            ;;
    esac

    rm -f cli_out
}

#
# MAIN
#

# sanity checks, avoid an avalanche of errors
if [ ! -x "$P_SRV" ]; then
    echo "Command '$P_SRV' is not an executable file"
    exit 1
fi
if [ ! -x "$P_CLI" ]; then
    echo "Command '$P_CLI' is not an executable file"
    exit 1
fi
if which $OPENSSL >/dev/null 2>&1; then :; else
    echo "Command '$OPENSSL' not found"
    exit 1
fi

get_options "$@"

killall -q openssl ssl_server ssl_server2
trap cleanup INT TERM HUP

for VERIFY in $VERIFIES; do
    for MODE in $MODES; do
        for TYPE in $TYPES; do

            setup_arguments
            setup_ciphersuites

            if [ "X" != "X$P_CIPHERS" ]; then
                start_server "OpenSSL"
                for i in $P_CIPHERS; do
                    run_client PolarSSL $i
                done
                stop_server
            fi

            if [ "X" != "X$O_CIPHERS" ]; then
                start_server "PolarSSL"
                for i in $O_CIPHERS; do
                    run_client OpenSSL $i
                done
                stop_server
            fi

            add_polarssl_ciphersuites

            if [ "X" != "X$P_CIPHERS" ]; then
                start_server "PolarSSL"
                for i in $P_CIPHERS; do
                    run_client PolarSSL $i
                done
                stop_server
            fi

        done
    done
done

echo "------------------------------------------------------------------------"

if (( failed != 0 ));
then
    echo -n "FAILED"
else
    echo -n "PASSED"
fi

let "passed = tests - failed"
echo " ($passed / $tests tests ($skipped skipped))"

exit $failed
