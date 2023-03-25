global class Reporting
{
    global Reporting(ApexPages.StandardController controller) { }
    
    @RemoteAction
    global static String InitializeFilters(String inputStr)
    {
      ReportingObjects.FilterInput inputObj = (ReportingObjects.FilterInput)JSON.deserialize(inputStr, ReportingObjects.FilterInput.class);

      Map<String, Schema.SObjectType> getDesc = Schema.getGlobalDescribe();
      Set<String> objectKeys = getDesc.keySet();
      Schema.SObjectType systemObjectType;
      Schema.DescribeSObjectResult sysObjRes;
      Map<String, Schema.SObjectField> fieldMap;
      Map<String, Schema.RecordTypeInfo> recordMap;
      Schema.SObjectField field;
      Schema.DescribeFieldResult fieldDesc;

      for (ReportingObjects.filterObject fo : inputObj.filterList)
      {
        if (fo.entries == null)
        {
          fo.entries = new List<ReportingObjects.filterEntry>();
        }
        if (fo.Name == null || fo.Name == '')
        {
            continue;
        }
        if (fo.type == 'Picklist')
        {
          systemObjectType = getDesc.get(fo.object_type);
          sysObjRes = systemObjectType.getDescribe();
          fieldMap = sysObjRes.fields.getMap();

          field = fieldMap.get(fo.field_name);
          fieldDesc = field.getDescribe();
          for (PickListEntry ple : fieldDesc.getPicklistValues())
          {
              fo.entries.add(new ReportingObjects.filterEntry(ple.getValue(), ple.getLabel()));
          }
        }
        else if (fo.type == 'Record List')
        {
          Boolean hasLabel = fo.label != '' && fo.label != null && fo.label != fo.value;
          Boolean hasOrder = fo.order != '' && fo.order != null && fo.order != fo.value && fo.order != fo.label;

          ReportingObjects.ReportInput ri = new ReportingObjects.ReportInput();
          ri.objType = fo.object_type;
          ri.selectClause = fo.value
                          + (hasLabel ? ',' + fo.label : '')
                          + (hasOrder ? ',' + fo.order : '')
                          ;
          ri.whereClause = fo.whereClause;
          ri.orderClause = (fo.order != '' & fo.order != null ? fo.order : (hasLabel ? fo.Label : fo.Value) + ' asc');

          ReportingObjects.ListOutput lObj = ReturnRecordList_Inner(ri);
          
          for (integer ndx = 0; ndx < lObj.recordData.size(); ndx++)
          {
            // [Value, Name, Order]
            List<string> entry = lObj.recordData[ndx];
            fo.entries.add(new ReportingObjects.filterEntry(entry[0], hasLabel ? entry[1] : entry[0]));
          }
        }
        else if (fo.type == 'Record Type')
        {
          systemObjectType = getDesc.get(fo.object_type);
          sysObjRes = systemObjectType.getDescribe();
          recordMap = sysObjRes.getRecordTypeInfosByName();
          for (RecordTypeInfo rti : recordMap.values())
          {
              //if (rti.getName() != 'Master')
              //{
                fo.entries.add(new ReportingObjects.filterEntry(rti.getRecordTypeId(), rti.getName()));
              //}
          }
        }
        else if (fo.type == 'Reference')
        {
          // Hold for now, do at end
        }
        else // 'Manual', 'Date', 'DateTime-Local', 'Number', 'Text'
        {
          // Do nothing; this filter was passed in fully formed
        }
      }

      for (ReportingObjects.filterObject fo : inputObj.filterList)
      {
        if (fo.type == 'Reference')
        {
          for (ReportingObjects.filterObject rfo : inputObj.filterList)
          {
            if (fo.object_type == rfo.name)
            {
              fo.entries = rfo.entries;
              fo.object_type = rfo.object_type;
              fo.type = rfo.type;
              fo.value = rfo.value;
              fo.order = rfo.order;
              fo.filter = rfo.filter;
            }
          }
        }
      }

      return JSON.serialize(inputObj);

    }

    @RemoteAction
    global static String OpenedVsClosed(String inputStr)
    {
        ReportingObjects.ReportInput inputObj = (ReportingObjects.ReportInput)JSON.deserialize(inputStr, ReportingObjects.ReportInput.class);

        String objType = inputObj.objType;
        String startDatestr = inputObj.startDatestr;
        String endDatestr = inputObj.endDatestr;
        String whereClause = inputObj.whereClause;
        
        // Convert input strings to datetimes (yyyy-MM-dd HH:mm:ss)
        Datetime startDate;
        if (startDatestr == null || startDatestr == '')
        {
            startDate = datetime.valueOf('2013-01-01 00:00:00');
        }
        else
        {
            startDate = datetime.valueOf(startDatestr.Replace('T', ' ' ).Replace('Z',''));
        }
        
        Datetime endDate;
        if (endDatestr == null || endDatestr == '')
        {
            endDate = datetime.valueOf('2057-12-31 00:00:00');
        }
        else
        {
            endDate = datetime.valueOf(endDatestr.Replace('T', ' ' ).Replace('Z',''));
        }

        // Define x-axis labels and initialize lists for counts
        ReportingObjects.TrendOutput chartDt = new ReportingObjects.TrendOutput();
        Date dayone = date.newinstance(startDate.year(), startDate.month(), startDate.day());
        Date dayend = date.newinstance(endDate.year(), endDate.month(), endDate.day());
        Integer dayCount = dayone.daysBetween(dayend);
        for (Integer i = 0; i <= dayone.daysBetween(dayend); i++)
        {
            chartDt.xLabels.add(dayone.addDays(i));
            chartDt.opened.add(0);
            chartDt.closed.add(0);
            chartDt.truth.add(0);
            chartDt.cumulative.add(0);
            chartDt.net.add(0);
        }

        // Define valuable variables
        String soql = '';
        
        Integer openingCount;
        Integer startAt;
        Date compDt;
        Integer val;
        AggregateResult[] trend;
        
        string[] strOpen = new string[]{'CreatedDate'};
        string[] strClose = new string[]{'ClosedDate'};
        
        string openQuery = 'SELECT COUNT()'
                         + '  FROM ' + objType
                         + ' WHERE {0} <= :startDate AND ({1} >= :startDate OR {1} = null)'
                         + '   AND ' + whereClause.replaceAll('\'', '\'\'');
                         
        string trendQuery = 'SELECT DAY_ONLY({0}) compDt, COUNT(Id) val'
                          + '  FROM ' + objType
                          + ' WHERE {0} >= :startDate AND {0} <= :endDate'
                          + (objType == 'EmailMessage' ? ' AND Incoming = {1}' : '')
                          + '   AND ' + whereClause.replaceAll('\'', '\'\'')
                          + ' GROUP BY DAY_ONLY({0})'
                          + ' ORDER BY DAY_ONLY({0})';
        
        string cumulQuery = 'SELECT DAY_ONLY({0}) compDt, COUNT(Id) val'
                          + '  FROM ' + objType
                          + ' WHERE {0} >= :startDate AND ({1} >= :endDate OR {1} = null)'
                          + '   AND ' + whereClause.replaceAll('\'', '\'\'')
                          + ' GROUP BY DAY_ONLY({0})'
                          + ' ORDER BY DAY_ONLY({0})';
        
        if (objType == 'Task')
        {
            strClose[0] = 'ClosedDate__c';
        }
        else if (objType == 'EmailMessage')
        { // emails filtered by "incoming" field
            strClose[0] = 'CreatedDate';
            strOpen.add('true');
            strClose.add('false');
        }
        if (inputObj.startDateField != null && inputObj.startDateField != '')
        {
            strOpen[0] = inputObj.startDateField;
        }
        if (inputObj.endDateField != null && inputObj.endDateField != '')
        {
            strClose[0] = inputObj.endDateField;
        }
        
        //
        // CALCULATE STARTING 'OPEN' COUNT
        //
        soql = string.format(openQuery, new string[]{strOpen[0],strClose[0]});
        system.debug(soql);
    
        openingCount = Database.countQuery(soql);
    
        // Initialize arrays
        for (Integer i = 0; i <= dayone.daysBetween(dayend); i++)
        {
            chartDt.truth.set(i, openingCount);
        }
        
        
        //
        // CALCULATE 'OPENED TREND'
        //
        soql = string.format(trendQuery, strOpen);
        system.debug(soql);
        
        trend = Database.query(soql);
        
        startAt = 0; // slides the start of the inner loop as we progress through the results
        for (AggregateResult ar : trend)
        {
            compDt = ReportingObjects.getUTCDate(Date.valueOf(ar.get('compDt')));
            val = Integer.valueOf(ar.get('val'));
            
            for (Integer i = startAt; i <= dayCount; i++)
            {
                if (compDt == chartDt.xLabels.get(i))
                {
                    chartDt.opened.set(i, val);
                    
                    for (Integer j = i; j <= dayCount; j++)
                    {
                        chartDt.truth.set(j, chartDt.truth.get(j) + val);
                    }
                    startAt = i;
                    break;
                }
            }
        }
        
        
        //
        // CALCULATE 'CLOSED TREND'
        //
        soql = string.format(trendQuery, strClose);
        system.debug(soql);
        
        trend = Database.query(soql);
        
        startAt = 0; // slides the start of the inner loop as we progress through the results
        for (AggregateResult ar : trend)
        {
            compDt = ReportingObjects.getUTCDate(Date.valueOf(ar.get('compDt')));
            val = Integer.valueOf(ar.get('val'));
            
            for (Integer i = startAt; i <= dayCount; i++)
            {
                if (compDt == chartDt.xLabels.get(i))
                {
                    chartDt.closed.set(i, val);
                    
                    for (Integer j = i; j <= dayCount; j++)
                    {
                        chartDt.truth.set(j, chartDt.truth.get(j) - val);
                    }
                    startAt = i;
                    break;
                }
            }
        }
        
        
        //
        // CALCULATE 'NET TREND'
        //
        for (Integer i = 0; i <= dayCount; i++)
        {
            chartDt.net.set(i, chartDt.net.get(i) + chartDt.truth.get(i) - openingCount);
        }
        
        
        //
        // CALCULATE 'CUMULATIVE TREND'
        //
        soql = string.format(cumulQuery, new string[]{strOpen[0], strClose[0]});
        system.debug(soql);
        
        trend = Database.query(soql);
        
        // Use startAt to intelligently seek through the list over time (slide the start of the inner loop)
        startAt = 0;
        integer prev = 0;
        for (AggregateResult ar : trend)
        {
            compDt = ReportingObjects.getUTCDate(Date.valueOf(ar.get('compDt')));
            val = Integer.valueOf(ar.get('val'));
            
            for (Integer i = startAt; i <= dayCount; i++)
            {
                if (compDt == chartDt.xLabels.get(i))
                {
                    if (i>0)
                    {
                        prev = chartDt.cumulative.get(i-1);
                    }
                    chartDt.cumulative.set(i, prev + val);
                    startAt = i;
                    break;
                }
            }
        }

        return JSON.serialize(new ReportingObjects.ReportOutput(inputObj, JSON.serialize(chartDt)));
    }

    @RemoteAction
    global static String FilterBy(String inputStr)
    {
        return JSON.serialize(FilterByBase((ReportingObjects.ReportInput)JSON.deserialize(inputStr, ReportingObjects.ReportInput.class)));
    }

    private static ReportingObjects.ReportOutput FilterByBase(ReportingObjects.ReportInput inputObj)
    {
        String objType = inputObj.objType;
        String whereClause = inputObj.whereClause;
        String groupClause = inputObj.groupClause;
        String orderClause = inputObj.orderClause;

        String aggregateFunction = inputObj.aggregateFunction;
        String aggregateField = inputObj.aggregateField;

        String comparisonOperator = inputObj.comparisonOperator;
        String[] forceValues = inputObj.forceValues;
        Integer maxResults = inputObj.maxResults;
        Double lowerThreshold = inputObj.lowerThreshold;
        
        String flds;
        if (aggregateField != null && aggregateField != '')
        {
            flds = groupClause + ',' + aggregateField;
        }
        else
        {
            flds = groupClause;
        }
        String soql = 'SELECT ' + flds
                    + ' FROM ' + objType
                    + ' WHERE ' + whereClause
                    + ((orderClause == null || orderClause == '') ? '' : ' ORDER BY ' + ReportingObjects.soqlInj(orderClause));

        list<SObject> objlst = Database.query(soql);

        if (objlst.size() == 0)
        {
            return new ReportingObjects.ReportOutput(inputObj);
        }

        // Initialize return value
        ReportingObjects.FilterOutput aggData = new ReportingObjects.FilterOutput();
        Integer defaultAggIndex = -1;

        // Ensure any values we _need_ to return are returned
        if (forceValues != null && forceValues.size() > 0)
        {
            for (String fv : forceValues)
            {
                aggData.counts.add(0);
                aggData.values.add(0);
                aggData.labels.add(fv);

                if ((fv == '*Unknown') || (fv == '*Other'))
                {
                  defaultAggIndex = aggData.labels.size() - 1;
                }
            }
        }

        // Loop over case list checking date from CreatedDate and ClosedDate (if closed)
        Boolean skipadd = false;
        Boolean match = false;
        String currLabel;
        String[] compVals = new String[]{};
        Double cv;

        List<String> train = new list<String>();
        List<String> filterfields = groupClause.split(',');
        for (SObject obj : objlst)
        {
            skipadd = false;

            for (String fld : filterfields)
            {
                String newval = String.valueOf(ReportingObjects.extractField(fld, obj));
                compVals.add(newval);
            }

            currLabel = String.join(compVals, ' | ');
            compVals.clear();
            match = false;

            for (Integer i = 0; i < aggData.labels.size(); i++)
            {

                if (comparisonOperator == '=')
                {
                    match = (currLabel == aggData.labels.get(i));
                }
                else if (comparisonOperator == 'like')
                {
                    match = (currLabel.toLowerCase().contains(aggData.labels.get(i).toLowerCase()));
                }

                if (match)
                {
                    aggData.counts.set(i, aggData.counts.get(i) + 1);

                    // Add compiled value to array
                    if (aggregateField != null && aggregateField != '')
                    {
                        if (aggregateFunction == 'sum' || aggregateFunction == null || aggregateFunction == '')
                        {
                            aggData.values.set(i, aggData.values.get(i) + Double.valueOf(ReportingObjects.extractField(aggregateField, obj)));
                        }
                    }

                    skipadd = true;
                    break;
                }
            }
            if ((skipadd == false) && (forceValues == null || forceValues.size() == 0))
            {
                // Add new entry to return data
                aggData.labels.add(currLabel);
                aggData.counts.add(1);

                if (aggregateField != null && aggregateField != '')
                {
                    aggData.values.add(Double.valueOf(ReportingObjects.extractField(aggregateField, obj)));
                }
            }
            else if ( (skipadd == false) && (defaultAggIndex > -1) )
            {
                aggData.counts.set(defaultAggIndex, aggData.counts.get(defaultAggIndex) + 1);

                // Add compiled value to array
                if (aggregateField != null && aggregateField != '')
                {
                    aggData.values.set(defaultAggIndex, aggData.values.get(defaultAggIndex) + Double.valueOf(ReportingObjects.extractField(aggregateField, obj)));
                }
            }
        }

        // Create values if no field was passed in
        if (aggregateField == null || aggregateField == '')
        {
            aggData.values = aggData.counts.clone();
        }
        
        if (maxResults > 0 && (lowerThreshold == null || lowerThreshold < 0))
        {
            aggData.sort(maxResults);
        }

        return new ReportingObjects.ReportOutput(inputObj, JSON.serialize(aggData));
    }


    @RemoteAction
    global static String GroupBy(String inputStr)
    {
        ReportingObjects.ReportInput inputObj = (ReportingObjects.ReportInput)JSON.deserialize(inputStr, ReportingObjects.ReportInput.class);

        String objType = inputObj.objType;
        String whereClause = inputObj.whereClause;
        String groupClause = inputObj.groupClause;
        String orderClause = inputObj.orderClause;

        String aggregateFunction = inputObj.aggregateFunction;
        String aggregateField = inputObj.aggregateField;
        
        if (aggregateFunction == null || aggregateFunction == '') { aggregateFunction = 'COUNT'; }
        if (aggregateField == null || aggregateField == '') { aggregateField = 'Id'; }

        String comparisonOperator = inputObj.comparisonOperator;
        String[] forceValues = inputObj.forceValues;
        Integer maxResults = inputObj.maxResults;
        Double lowerThreshold = inputObj.lowerThreshold;
        
        Boolean setLimit = ((maxResults > 0) && (lowerThreshold == null || lowerThreshold < 0));
        
        String flds;
        flds = groupClause + ',' + aggregateFunction + '(' + aggregateField + ') val, COUNT(Id) cnt';
        
        String soql = 'SELECT ' + flds
                    + ' FROM ' + objType
                    + ' WHERE ' + whereClause
                    + ' GROUP BY ' + groupClause
                    + ((orderClause == null || orderClause == '') ? 
                        (!setLimit ? '' : ' ORDER BY ' + aggregateFunction + '(' + aggregateField + ')')
                    : ' ORDER BY ' + ReportingObjects.soqlInj(orderClause))
                    + (!setLimit ? '' : ' LIMIT ' + String.valueOf(maxResults));
        system.debug(soql);
        list<AggregateResult> objlst = Database.query(soql);

        if (objlst.size() == 0)
        {
            return JSON.serialize(new ReportingObjects.ReportOutput(inputObj));
        }

        // Initialize return value
        ReportingObjects.FilterOutput aggData = new ReportingObjects.FilterOutput();
        Integer defaultAggIndex = -1;

        String[] compVals = new String[]{};
        List<String> filterfields = groupClause.split(',');

        for (AggregateResult obj : objlst)
        {
            for (String fld : filterfields)
            {
                String newval = String.valueOf(ReportingObjects.extractField(fld, obj));
                compVals.add(newval);
            }
            String currLabel = String.join(compVals, ' | ');
            compVals.clear();

            aggData.labels.add(currLabel);
            aggData.counts.add(Integer.valueOf(ReportingObjects.extractField('cnt', obj)));
            aggData.values.add(Double.valueOf(ReportingObjects.extractField('val', obj)));
        }

        // Ensure any values we _need_ to return are returned
        if (forceValues != null && forceValues.size() > 0)
        {
            for (String fv : forceValues)
            {
                boolean mustAdd = true;
                for (String val : aggData.labels)
                {
                    if (val == fv)
                    {
                        mustAdd = false;
                        break;
                    }
                }
                if (mustAdd)
                {
                    aggData.counts.add(0);
                    aggData.values.add(0);
                    aggData.labels.add(fv);
                }
            }
        }

        return JSON.serialize(new ReportingObjects.ReportOutput(inputObj, JSON.serialize(aggData)));
    }


    @RemoteAction
    global static String TrendData(String inputStr)
    {
        ReportingObjects.ReportInput[] inputObjs = (ReportingObjects.ReportInput[])JSON.deserialize(inputStr, ReportingObjects.ReportInput[].class);
        String[] chartsData = new String[]{};

        for (ReportingObjects.ReportInput inputObj : inputObjs)
        {
          ReportingObjects.ReportOutput rezObj = FilterByBase(inputObj);

          ReportingObjects.AdHocOutput chartData = new ReportingObjects.AdHocOutput();

          if (rezObj.chartsdata != null && rezObj.chartsdata.size() > 0)
          {
              ReportingObjects.FilterOutput dataObj = (ReportingObjects.FilterOutput)JSON.deserialize(rezObj.chartsdata[0], ReportingObjects.FilterOutput.class);

              chartData.yValues = dataObj.values;
              chartData.xLabels = dataObj.labels;
              chartData.xValues = dataObj.counts; // dummy values - these are not used (currently)
          }
          chartsData.add(JSON.serialize(chartData));
        }

        return JSON.serialize(new ReportingObjects.ReportOutput(inputObjs, chartsData));
    }


    @RemoteAction
    global static String ReturnRecordList(String inputStr)
    {
        ReportingObjects.ReportInput inputObj = (ReportingObjects.ReportInput)JSON.deserialize(inputStr, ReportingObjects.ReportInput.class);
        ReportingObjects.ListOutput listData = ReturnRecordList_Inner(inputObj);
        return JSON.serialize(new ReportingObjects.ReportOutput(inputObj, JSON.serialize(listData)));
    }


    private static ReportingObjects.ListOutput ReturnRecordList_Inner(ReportingObjects.ReportInput inputObj)
    {
        String objType = inputObj.objType;
        String selectClause = inputObj.selectClause;
        String whereClause = inputObj.whereClause;
        String orderClause = inputObj.orderClause;

        String soql = 'SELECT ' + selectClause // ReportingObjects.soqlInj(selectClause)
                    + '  FROM ' + ReportingObjects.soqlInj(objType)
                    + ' WHERE ' + ReportingObjects.soqlInj(whereClause, true)
                    + ((orderClause == null || orderClause == '') ? '' : ' ORDER BY ' + ReportingObjects.soqlInj(orderClause));
        System.Debug(soql);
        list<SObject> objlst = Database.query(soql);

        String bodystr = '';
        String headerstr = '';

        ReportingObjects.ListOutput listData = new ReportingObjects.ListOutput();
        listData.fieldList = selectClause.split(',');
        listData.labelList = selectClause.replaceAll('__c', '').replaceAll('__r', '').replaceAll('_', ' ').replaceAll('\\.', ' ').split(',');

        String fval;
        Integer rowCtr = -1;
        for (SObject gobj : objlst)
        {
            rowCtr++;
            listData.recordData.Add(new String[]{});
            for (String field : listData.fieldList)
            {
                field = field.trim();

                fval = String.valueOf(ReportingObjects.extractField(field, gobj));

                if (fval == null)
                {
                    fval = '';
                }
                listData.recordData.get(rowCtr).add(fval);
            }
        }
        
        return listData;
    }


    @RemoteAction
    global static String GenerateGrid(String inputStr)
    {
        List<List<ReportingObjects.ReportInput>> inputObjs = (List<List<ReportingObjects.ReportInput>>)JSON.deserialize(inputStr, List<List<ReportingObjects.ReportInput>>.class);

        List<ReportingObjects.ReportOutput> retVal = new List<ReportingObjects.ReportOutput>();

        ReportingObjects.ReportOutput newRow;
        for (Integer row = 0; row < inputObjs.size(); row++)
        {
          newRow = new ReportingObjects.ReportOutput();
          for (Integer col = 0; col < inputObjs[row].size(); col++)
          {
            newRow.inputData.add(inputObjs[row][col]);
            newRow.chartsData.add(GenerateMetric(inputObjs[row][col]));
          }
          retVal.add(newRow);
        }

        return JSON.serialize(retVal);
    }


    private static String GenerateMetric(ReportingObjects.ReportInput inputObj)
    {
        if (inputObj.chartType == 'label' || inputObj.chartType == 'header' || inputObj.chartType == 'formula')
        {
          return inputObj.label;
        }

        if (inputObj.chartType == null || inputObj.chartType == '' || inputObj.chartType == 'metric')
        {
          inputObj.chartType = 'integer';
        }
        
        if (inputObj.aggregateField == null) { inputObj.aggregateField = ''; }
        
        String objType = inputObj.objType;
        String selectClause = ReportingObjects.soqlInj(inputObj.aggregateFunction) + '(' + ReportingObjects.soqlInj(inputObj.aggregateField) + ')';//soqlInj(inputObj.selectClause);
        String whereClause = inputObj.whereClause;
        String orderClause = inputObj.orderClause;
        String groupClause = inputObj.groupClause;

        String soql = 'SELECT ' + selectClause
                    + '  FROM ' + ReportingObjects.soqlInj(objType)
                    + ((whereClause == null || whereClause == '') ? '' : ' WHERE ' + ReportingObjects.soqlInj(whereClause, true))
                    + ((groupClause == null || groupClause == '') ? '' : ' GROUP BY ' + ReportingObjects.soqlInj(groupClause))
                    + ((orderClause == null || orderClause == '') ? '' : ' ORDER BY ' + ReportingObjects.soqlInj(orderClause));

        System.debug(soql);

        if (inputObj.aggregateFunction == 'COUNT' && inputObj.aggregateField == '')
        {
          return String.valueOf(Database.countQuery(soql));
        }
        else if (inputObj.chartType == 'integer' || inputObj.chartType == 'negative_integer')
        {
          AggregateResult[] ar = Database.query(soql);
          return String.valueOf(Integer.valueOf(ar[0].get('expr0')));
        }
        else if (inputObj.chartType == 'double' || inputObj.chartType == 'negative_double')
        {
          AggregateResult[] ar = Database.query(soql);
          return String.valueOf(Double.valueOf(ar[0].get('expr0')));
        }

        return '';
    }
}