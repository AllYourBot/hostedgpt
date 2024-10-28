import*as e from"tailwindcss/plugin";var a=e;try{"default"in e&&(a=e.default)}catch(e){}var t={};const s=a;const n=s((({addUtilities:e,matchUtilities:a,theme:t})=>{const s={".m-safe":{marginTop:"env(safe-area-inset-top)",marginRight:"env(safe-area-inset-right)",marginBottom:"env(safe-area-inset-bottom)",marginLeft:"env(safe-area-inset-left)"},".mx-safe":{marginRight:"env(safe-area-inset-right)",marginLeft:"env(safe-area-inset-left)"},".my-safe":{marginTop:"env(safe-area-inset-top)",marginBottom:"env(safe-area-inset-bottom)"},".mt-safe":{marginTop:"env(safe-area-inset-top)"},".mr-safe":{marginRight:"env(safe-area-inset-right)"},".mb-safe":{marginBottom:"env(safe-area-inset-bottom)"},".ml-safe":{marginLeft:"env(safe-area-inset-left)"},".p-safe":{paddingTop:"env(safe-area-inset-top)",paddingRight:"env(safe-area-inset-right)",paddingBottom:"env(safe-area-inset-bottom)",paddingLeft:"env(safe-area-inset-left)"},".px-safe":{paddingRight:"env(safe-area-inset-right)",paddingLeft:"env(safe-area-inset-left)"},".py-safe":{paddingTop:"env(safe-area-inset-top)",paddingBottom:"env(safe-area-inset-bottom)"},".pt-safe":{paddingTop:"env(safe-area-inset-top)"},".pr-safe":{paddingRight:"env(safe-area-inset-right)"},".pb-safe":{paddingBottom:"env(safe-area-inset-bottom)"},".pl-safe":{paddingLeft:"env(safe-area-inset-left)"},".top-safe":{top:"env(safe-area-inset-top)"},".right-safe":{right:"env(safe-area-inset-right)"},".bottom-safe":{bottom:"env(safe-area-inset-bottom)"},".left-safe":{left:"env(safe-area-inset-left)"},".min-h-screen-safe":{minHeight:["calc(100vh - (env(safe-area-inset-top) + env(safe-area-inset-bottom)))","-webkit-fill-available"]},".max-h-screen-safe":{maxHeight:["calc(100vh - (env(safe-area-inset-top) + env(safe-area-inset-bottom)))","-webkit-fill-available"]},".h-screen-safe":{height:["calc(100vh - (env(safe-area-inset-top) + env(safe-area-inset-bottom)))","-webkit-fill-available"]}};e(s);const n=Object.entries(s).reduce(((e,[a,t])=>{const s=a.slice(1);e[`${s}-offset`]=e=>Object.entries(t).reduce(((a,[t,s])=>{Array.isArray(s)?a[t]=s.map((a=>a==="-webkit-fill-available"?a:`calc(${a} + ${e})`)):a[t]=`calc(${s} + ${e})`;return a}),{});return e}),{});a(n,{values:t("spacing"),supportsNegativeValues:true});const i=Object.entries(s).reduce(((e,[a,t])=>{const s=a.slice(1);e[`${s}-or`]=e=>Object.entries(t).reduce(((a,[t,s])=>{Array.isArray(s)?a[t]=s.map(((a,t)=>a==="-webkit-fill-available"?a:`max(${a}, ${e})`)):a[t]=`max(${s}, ${e})`;return a}),{});return e}),{});a(i,{values:t("spacing"),supportsNegativeValues:true})}));t=n;var i=t;export{i as default};

