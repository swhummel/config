#!/usr/bin/env bash
set -euo pipefail

INPUT_FILE="${1:-git_performance.log}"
OUTPUT_FILE="${2:-git_performance.svg}"

[[ -f "$INPUT_FILE" ]] || { echo "Input file not found: $INPUT_FILE" >&2; exit 1; }

awk '
BEGIN {
  bar_w=30; gap=5; day_gap=300; ymax=10
  left=80; right=20; top=40; bottom=80
  count=0
}

$2=="-" && $4=="-" {
  count++
  dur=$3; sub(/s$/,"",dur)
  duration[count]=dur+0
  logline[count]=$0
  day[count]=substr($1,1,8)
  daylabel[count]=substr($1,7,2) "." substr($1,5,2) "."
}

END {
  if(count==0) exit 1

  x=left
  prev=""
  for(i=1;i<=count;i++){
    if(i>1 && day[i]!=day[i-1]) x+=day_gap
    xpos[i]=x
    x+=bar_w+gap
  }

  width=x+right
  height=900
  plot_h=height-top-bottom

  print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  print "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"" width "\" height=\"" height "\">"
  print "<rect width=\"100%\" height=\"100%\" fill=\"white\"/>"

  for(v=0;v<=10;v++){
    y=height-bottom-(v/ymax)*plot_h
    printf "<line x1=\"%d\" y1=\"%.1f\" x2=\"%d\" y2=\"%.1f\" stroke=\"#ddd\"/>\n",left,y,width-right,y
    printf "<text x=\"%d\" y=\"%.1f\" text-anchor=\"end\">%ds</text>\n",left-10,y+4,v
  }

  y1=height-bottom-(1/ymax)*plot_h
  printf "<line x1=\"%d\" y1=\"%.1f\" x2=\"%d\" y2=\"%.1f\" stroke=\"black\" stroke-dasharray=\"5,5\"/>\n",left,y1,width-right,y1

  prev=""
  for(i=1;i<=count;i++){
    if(daylabel[i]!=prev){
      printf "<line x1=\"%.1f\" y1=\"%d\" x2=\"%.1f\" y2=\"%d\" stroke=\"#999\"/>\n",xpos[i],top,xpos[i],height-bottom
      printf "<text x=\"%.1f\" y=\"%d\">%s</text>\n",xpos[i],height-bottom+20,daylabel[i]
      prev=daylabel[i]
    }
  }

  for(i=1;i<=count;i++){
    v=duration[i]
    dv=(v>10)?10:v
    h=(dv/ymax)*plot_h
    y=height-bottom-h

    c="#00aa00"
    if(v>=1 && v<=10) c="#ffd700"
    if(v>10) c="#ff0000"

    printf "<rect x=\"%.1f\" y=\"%.1f\" width=\"%d\" height=\"%.1f\" fill=\"%s\"><title>%s</title></rect>\n", xpos[i],y,bar_w,h,c,logline[i]
  }

  print "</svg>"
}
' "$INPUT_FILE" > "$OUTPUT_FILE"
