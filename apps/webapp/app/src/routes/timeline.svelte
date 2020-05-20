<script>
 import { scaleLinear, scaleTime } from 'd3-scale';
 import * as d3 from 'd3';
 import { afterUpdate } from 'svelte';
 import {
   first,
   last
 } from 'lodash-es';
 import dayjs from 'dayjs';
 import stats from '../data/release_stats.json';
 import timeline from '../data/timeline.json';

 const padding = { top: 20, right: 15, bottom: 20, left: 25 };
 // create an array of numbers from 0 to max, incremented by step
 const range = (max, step) => [...Array(max + 1).keys()].filter(n => n % step === 0)
 const dates = stats.map(s => s.date);
 let width = 900;
 let height = 400;

 // y is total percentage, from 0 to 100
 const yTicks = range(500, 100);

 // Coverage is sorted by timestamp, with oldest at [0]
 // X ticks will be from oldest audit run to today.
 let xTicks = [
   dayjs(first(dates)).subtract(1, 'day'),
   dayjs().subtract(24, 'month'),
   dayjs().subtract(18, 'month'),
   dayjs().subtract(12, 'month'),
   dayjs().subtract(6, 'month'),
   dayjs(last(dates)).add(1,'week')
 ];

 let betweenDates = (date, dates, stats) => {
   let isBeforeDates = dates.filter(d => dayjs(d).isAfter(date));
   let beforeIndex = isBeforeDates.length > 0
                                     ? dates.indexOf(first(isBeforeDates))
                                     : dates.indexOf(last(dates));
   let afterIndex = beforeIndex === 0
                  ? beforeIndex
                  : beforeIndex - 1;
   return {
     before: {
       total: stats[beforeIndex].endpoints.eligibleStable,
       tested: stats[beforeIndex].confTested.stable,
       date: stats[beforeIndex].date
     },
     after: {
       date: stats[afterIndex].date,
       total: stats[afterIndex].endpoints.eligibleStable,
       tested: stats[afterIndex].confTested.stable
     }
   }
 };

 let statsAtDate = (date, dates, stats) => {
   let { before, after } = betweenDates(date, dates, stats);
   console.log({before, after});
   let timespan = dayjs(before.date).diff(dayjs(after.date), 'day');
   let differenceInEndpoints = before.total - after.total;
   let endpointsPerDay = differenceInEndpoints / timespan;
   let differenceInTests = before.tested - after.tested;
   let testsPerDay = differenceInTests / timespan;
   let differenceInDays = dayjs(date).diff(dayjs(before.date),'day');
   let endpointsAtDate = before.total + (endpointsPerDay * differenceInDays);
   let testsAtDate = before.tested + (testsPerDay * differenceInDays);
   return {
     total: endpointsAtDate,
     totalText: `~${Math.floor(endpointsAtDate)} stable, eligible endpoints`,
     tested: testsAtDate,
     testedText: `~${Math.floor(testsAtDate)} covered by conformance tests`,
   }
 };

 let presentDay = dayjs('2020-05-19');

 $: currentEvent = presentDay;
 $: currentStats = statsAtDate(currentEvent, dates, stats);

 let minX = dayjs(first(dates));
 let maxX = dayjs(last(dates));
 let xScale = scaleTime()
   .domain([minX, maxX])
   .range([padding.left, width - padding.right]);

 let yScale = scaleLinear()
   .domain([Math.min.apply(null, yTicks), Math.max.apply(null, yTicks)])
   .range([height - padding.bottom, padding.top]);

 let totalStableEndpointsPath = `M${stats.map(s => `${xScale(dayjs(s.date))},${yScale(s.endpoints.eligibleStable)}`).join('L')}`;
 let totalStableArea = `${totalStableEndpointsPath}L${xScale(maxX)}, ${yScale(0)}L${xScale(minX)},${yScale(0)}Z`;

 let confTestPath = `M${stats.map(s => `${xScale(dayjs(s.date))},${yScale(s.confTested.stable)}`).join('L')}`;
 let confTestArea = `${confTestPath}L${xScale(maxX)}, ${yScale(0)}L${xScale(minX)},${yScale(0)}Z`;

 afterUpdate(() => console.log({currentStats}));
</script>

<h1>Stable, Eligible Endpoints covered by tests</h1>
<div class="chart" bind:clientWidth={width} bind:clientHeight={height}>
  <svg>
    <!-- y axis -->
    <g class='axis y-axis' transform="translate(0, {padding.top})">
      {#each yTicks as tick}
        <g class="tick tick-{tick}"
          transform="translate(0, {yScale(tick) - padding.bottom})">
          <line x2="100%"></line>
          <text y="-4">{tick} {tick === 500 ? '   stable, eligible endpoints' : ''}</text>
        </g>
      {/each}
    </g>
    <!-- x axis -->
    <g class="axis x-axis">
      {#each xTicks as tick}
        <g class="tick tick-{ tick}" transform="translate({xScale(tick)},{height})">
          <line y1="-{height}" y2="-{padding.bottom}" x1="0" x2="0"></line>
          <text y="-2">{dayjs(tick).format('MMM, YY')}</text>
        </g>
      {/each}
    </g>
    <!-- timeline: vertical line tracking current hovered event -->
    <g class='timeline'
    transform="translate({xScale(currentEvent)}, {height})">
      <line
        y1="-{height}"
        y2="-{padding.bottom}"
        x1="0"
        x2="0">
      </line>
    </g>
    <circle
      class='event'
      fill="indigo"
      r="5"
      cy={yScale(currentStats.total)}
      cx={xScale(currentEvent)}
    />
    <text
      x={xScale(currentEvent) + 3}
      y={yScale(currentStats.total) - 10}>
      {currentStats.totalText}
      </text>
 <circle
      class='event'
      fill="indigo"
      r="5"
      cy={yScale(currentStats.tested)}
      cx={xScale(currentEvent)}
    />
 <text
   x={xScale(currentEvent) + 3}
   y={yScale(currentStats.tested) - 10}>
   {currentStats.testedText}
 </text>
    <!-- Endpoint Coverage -->
    <path class='path-line' d={totalStableEndpointsPath}></path>
    <path class='path-area' d={totalStableArea}></path>
    <path class='path-line conf' d={confTestPath}></path>
    <path class='path-area conf' d={confTestArea}></path>
  </svg>
</div>
<ul id='timeline' on:mouseout={() => currentEvent = presentDay}>
  {#each timeline as event}
    <li on:mouseover={() => currentEvent = dayjs(event.date)}>
      <strong>{dayjs(event.date).format('MMM, YYYY')}</strong>
      <p>{event.event}</p>
    </li>
  {/each}
</ul>


<style>
 g.timeline line {
   stroke: orange;
   }
 .chart {
   max-width: 900px;
   margin-left: auto;
   margin-right: auto;
 }

 ul#timeline {
   border: 1px solid gray;
   list-style-type: none;
   padding: 0;
   max-width: 400px;
   font-size: 0.85rem;
 }
 ul#timeline li {
   display: grid;
   grid-template-columns: 4.5rem 1fr;
   padding: 0.5rem;
   margin: 0;
   border-bottom: 1px dashed gray;
 }

 ul#timeline li:hover {
   background: rgba(234, 226, 108, 0.2);
 }

 ul#timeline strong , ul#timeline p{
   padding: 0;
   margin: 0;
   }
 ul#timeline strong {
   text-align: right;
   font-weight: 200;
   font-style: italic;
 }
 ul#timeline p {
   padding-left: 1.5rem;
 }

 svg {
   position: relative;
   width: 100%;
   height: 450px;
   overflow: visible;
 }

 .tick {
   font-size: .725em;
   font-weight: 200;
 }

 .tick line {
   stroke: #aaa;
   stroke-dasharray: 2;
 }

 .tick text {
   fill: #666;
   text-anchor: start;
 }

 .tick.tick-0 line {
   stroke-dasharray: 0;
 }

 .x-axis .tick text {
   text-anchor: middle;
 }

 .path-line {
   fill: none;
   stroke: rgb(234,226,108);
   stroke-linejoin: round;
   stroke-linecap: round;
   stroke-width: 1;
 }

 .path-line.conf {
   stroke: rgb( 0, 100, 100);
 }

 .path-area.conf {
   fill: rgba(0, 100, 100, 0.2);
 }
 .path-area {
   fill: rgba(234, 226, 108, 0.2);
 }
</style>
