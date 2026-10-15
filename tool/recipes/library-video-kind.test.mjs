import test from 'node:test';
import assert from 'node:assert/strict';
import * as library from './build-recipe-library.mjs';
const video=()=>({sourceKind:'creator-youtube',youtubeDerived:true,sourceVideoId:'Abc_123-xyz',sourceUrl:'https://www.youtube.com/watch?v=Abc_123-xyz',runtimeReady:false,nutrition:null});
test('video facts require exact canonical video identity and explicit source kind',()=>{
 assert.equal(typeof library.validateCreatorSource,'function');
 assert.doesNotThrow(()=>library.validateCreatorSource(video(),'creator-youtube'));
 for(const edit of [{sourceKind:'creator-website'},{youtubeDerived:false},{youtubeDerived:null},{sourceVideoId:'bad'},{sourceVideoId:null},{sourceUrl:'https://www.youtube.com/watch?v=Zbc_123-xyz'},{sourceUrl:'https://example.org/watch?v=Abc_123-xyz'},{sourceUrl:'http://www.youtube.com/watch?v=Abc_123-xyz'}]){
  assert.throws(()=>library.validateCreatorSource({...video(),...edit},'creator-youtube'));
 }
 assert.throws(()=>library.validateCreatorSource(video(),'creator-website'));
 assert.doesNotThrow(()=>library.validateCreatorSource({sourceKind:'creator-website',youtubeDerived:false},'creator-website'));
});
