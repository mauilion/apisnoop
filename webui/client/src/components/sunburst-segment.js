import React, { Component } from 'react'
import SunburstChart from './sunburst-chart'


class SunburstSegment extends Component {
  render() {
    const {chartLocked,
           endpoints,
           focusChart,
           focusPath,
           focusPathAsString,
           lockChart,
           interiorLabel,
           release,
           sunburst,
           unfocusChart,
           unlockChart} = this.props

    return (
        <div id='sunburst-segment' className='bg_washed-red pa4 flex'>
        <div id='sunburst'>
        <h2>{release}</h2>
        {focusPathAsString.length > 0   ?
         <div className='h2 pa1'>{focusPathAsString}</div> :
         <div className='h2 pa1'>'Hover over Chart for Path'</div>
        }
      {chartLocked ? <strong>Click to Unlock</strong> : <strong>Click to Lock</strong>}

        <SunburstChart
          sunburst={sunburst}
          chartLocked={chartLocked}
          endpoints={endpoints}
          focusChart={focusChart}
          focusPath={focusPath}
          lockChart={lockChart}
          focusPathAsString={focusPathAsString}
          interiorLabel={interiorLabel}
          unfocusChart={unfocusChart}
          unlockChart={unlockChart}
        />
        </div>
        <div id='test-tags'>
        {(interiorLabel && interiorLabel.test_tags) &&
         <ul className='list ph3 ph5-ns pv4'>
           {displayTestTags(interiorLabel.test_tags)}
         </ul>
        }
        </div>
      </div>
    )

    function displayTestTags (testTags) {
      return testTags.map(testTag => {
        return (<li key={testTag} className='dib mr1 mb1' >
                <p className='f6 f5-ns b db pa2 mt0 mb0 link dim dark-gray ba b--black-20'>
                {testTag}
                </p>
                </li>)
      })
    }
  }
}

export default SunburstSegment