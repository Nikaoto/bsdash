
Go to here: Metrics > pick a dashboard > configure chart.

You'll see the default transform script that runs when new data arrives from an
SQL query.

```javascript
async (existingDataByQuery, newDataByQuery, completed) => {
  return Object.keys(newDataByQuery).reduce((result, queryIndex) => {
    result[queryIndex] = result[queryIndex].concat(newDataByQuery[queryIndex]);
    return result;
  }, existingDataByQuery);
}
```

This can be improved.
```javascript
async (existingDataByQuery, newDataByQuery, completed) => {
  for (const key in newDataByQuery)
    existingDataByQuery[key] = existingDataByQuery[key].concat(newDataByQuery[key]);
  return existingDataByQuery;
}
```

Now isn't that better? No `.reduce()` that makes the code harder to read, no
`Object.keys()` allocation and iteration and no annonymous function to call for
each element.

Let's measure the pefrormance now.


## The bench script

```javascript
const NUM_KEYS = 50;
const ARRAY_SIZE = 10000;
const RUNS = 100;
const ADDITIONAL = 1000;

// Generate fake data
function makeData(numKeys, arraySize) {
  const data = {};
  for (let i = 0; i < numKeys; i++) {
    const key = "query_" + i;
    data[key] = [];
    for (let j = 0; j < arraySize; j++) {
      data[key].push({
        timestamp: Date.now() + j,
        value: Math.random() * 100,
      });
    }
  }
  return data;
}

// Deep clone so each run starts fresh
function clone(obj) {
  const out = {};
  for (const k in obj) out[k] = obj[k].slice();
  return out;
}

const existing = makeData(NUM_KEYS, ARRAY_SIZE);
const newData = makeData(NUM_KEYS, ADDITIONAL);

function original(existingDataByQuery, newDataByQuery) {
  return Object.keys(newDataByQuery).reduce((result, queryIndex) => {
    result[queryIndex] = result[queryIndex].concat(newDataByQuery[queryIndex]);
    return result;
  }, existingDataByQuery);
}

function improved(existingDataByQuery, newDataByQuery) {
  for (const key in newDataByQuery)
    existingDataByQuery[key] = existingDataByQuery[key].concat(newDataByQuery[key]);
  return existingDataByQuery;
}

function bench(name, fn, runs) {
  const times = [];
  for (let i = 0; i < runs; i++) {
    const data = clone(existing);
    const start = performance.now();
    fn(data, newData);
    times.push(performance.now() - start);
  }
  const avg = times.reduce((a, b) => a + b) / times.length;
  const min = Math.min(...times);
  const max = Math.max(...times);
  console.log(`${name}: avg=${avg.toFixed(2)}ms  min=${min.toFixed(2)}ms  max=${max.toFixed(2)}ms`);
}

bench("original (reduce + concat)", original, RUNS);
bench("improved (for-in + push)  ", improved, RUNS);
```

## Results

With `RUNS = 100` in my browser (on a fresh tab):
```
original (reduce + concat): avg=0.50ms  min=0.10ms  max=18.10ms
improved (for-in + push)  : avg=0.31ms  min=0.10ms  max=1.00ms
```
Important to run this in a fresh tab so that V8 doesn't optimize the hot spots.

With `RUNS = 1000` in my browser (again on a fresh tab):
```
original (reduce + concat): avg=0.30ms  min=0.10ms  max=2.00ms
improved (for-in + push)  : avg=0.29ms  min=0.10ms  max=1.00ms
```

With `RUNS = 10000` in my browser (again on a fresh tab):
```
original (reduce + concat): avg=0.28ms  min=0.10ms  max=3.80ms
improved (for-in + push)  : avg=0.28ms  min=0.10ms  max=1.30ms
```

I assume V8 keeps finding and optimizing hot code, so the averages converge with
more runs.


I'd say we improved it!
