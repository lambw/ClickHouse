#!/usr/bin/env bash

CURDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$CURDIR"/../shell_config.sh

$CLICKHOUSE_CLIENT -q "DROP DATABASE IF EXISTS test_01107"
$CLICKHOUSE_CLIENT --allow_experimental_database_atomic=1 -q "CREATE DATABASE test_01107 ENGINE=Atomic"
$CLICKHOUSE_CLIENT -q "CREATE TABLE test_01107.mt (n UInt64) ENGINE=MergeTree() ORDER BY tuple()"

$CLICKHOUSE_CLIENT -q "INSERT INTO test_01107.mt SELECT number + sleepEachRow(3) FROM numbers(5)" &
sleep 1

$CLICKHOUSE_CLIENT -q "DETACH TABLE test_01107.mt"
$CLICKHOUSE_CLIENT -q "ATTACH TABLE test_01107.mt" 2>&1 | grep -F "Code: 57" > /dev/null && echo "OK"
$CLICKHOUSE_CLIENT -q "DETACH DATABASE test_01107" 2>&1 | grep -F "Code: 219" > /dev/null && echo "OK"

wait
$CLICKHOUSE_CLIENT -q "ATTACH TABLE test_01107.mt"
$CLICKHOUSE_CLIENT -q "SELECT count(n), sum(n) FROM test_01107.mt"
$CLICKHOUSE_CLIENT -q "DETACH DATABASE test_01107"
$CLICKHOUSE_CLIENT --allow_experimental_database_atomic=1 -q "ATTACH DATABASE test_01107"
$CLICKHOUSE_CLIENT -q "SELECT count(n), sum(n) FROM test_01107.mt"

$CLICKHOUSE_CLIENT -q "INSERT INTO test_01107.mt SELECT number + sleepEachRow(1) FROM numbers(5)" && echo "end" &
sleep 1
$CLICKHOUSE_CLIENT -q "DROP DATABASE test_01107" && sleep 1 && echo "dropped"
wait
