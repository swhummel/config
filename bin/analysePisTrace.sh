if [ $# -ge 2 ]
then
  REGEX="DistPrevStation|EEV Inf.*New cycle|updateRanDistance=|$1"
  shift
else
  REGEX="DistPrevStation|EEV Inf.*New cycle|updateRanDistance=|EEV Inf.*exprrepository.*KNOWN"
fi

egrep "$REGEX" $@ |\
gawk 'BEGIN {
}
/updateRanDistance=/ {
  DistPrevStation = $0;
  sub("^.*updateRanDistance=", "", DistPrevStation);
#  print "DistPrevStation = ", DistPrevStation;
}
/EEV Inf.*New cycle/ {
  CycleTime = $2;
  sub("\\..*$", "", CycleTime);
#  print "CycleTime = ", CycleTime;
  printf "%-s %6s m\n",  CycleTime, DistPrevStation;
}
/EEV Inf.*exprrepository.*KNOWN/ {
  name = $0;
  sub("^.*exprrepository[.:0-9]*  *", "", name);
  sub(" now .*KNOWN.*$", "", name);
  val = $0;
  sub("^.* now  *", "", val);
  if (allvars[name] != val)
  {
    allvars[name] = val;
    print name, "=", val;
  }
}
/EEV Inf.*exprrtvarrepos.*KNOWN/ {
  name = $0;
  sub("^.*exprrtvarrepos[.:0-9]*  *", "", name);
  sub(":New Value .*KNOWN.*$", "", name);
  val = $0;
  sub("^.*:New Value  *", "", val);
  if (allvars[name] != val)
  {
    allvars[name] = val;
    print name, "=", val;
  }
}
{
#  print CycleTime, DistPrevStation;
}
END {
}'
