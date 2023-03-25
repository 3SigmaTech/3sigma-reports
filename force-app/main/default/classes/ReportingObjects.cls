public class ReportingObjects
{
    //public ReportingObjects() { }

    public class ReportInput
    {
        public String selectClause {get; set;}
        public String objType {get; set;}
        public String whereClause {get; set;}
        public String groupClause {get; set;}
        public String orderClause {get; set;}

        public String xField {get; set;}
        public String[] yFields {get; set;}

        public String htmlElement {get; set;}
        public String legendContainer {get; set;}
        public String legendPosition {get; set;}
        public String[] chartColors {get; set;}
        public String[] chartStyles {get; set;}
        public List<List<String>> labelTranslations {get; set;}
        public String label {get; set;}
        public String title {get; set;}
        public Integer yAxis {get; set;}
        public Double seriesOffset {get; set;}

        public String startDatestr {get; set;}
        public String endDatestr {get; set;}
        
        public String startDateField {get; set;}
        public String endDateField {get; set;}
        
        public String chartType {get; set;}
        public String controlType {get; set;}

        public Double lowerThreshold {get; set;}
        public Integer maxResults {get; set;}
        public String comparisonOperator {get; set;}
        public String aggregateFunction {get; set;}
        public String aggregateField {get; set;}
        public String[] forceValues {get; set;}

        public String headers {get; set;}
        
        public String[] listHeaders {get; set;}
        public String listFormat {get; set;}

        public ReportInput()
        {
            selectClause = '';
            objType = '';
            whereClause = '';
            groupClause = '';
            orderClause = '';

            xField = '';
            yFields = new String[]{};

            htmlElement = '';
            legendContainer = '';
            legendPosition = '';
            chartColors = new String[]{};
            chartStyles = new String[]{};
            labelTranslations = new List<List<String>>();
            label = '';
            title = '';
            yAxis = 1;
            seriesOffset = 0;

            startDatestr = '';
            endDatestr = '';
            
            startDateField = '';
            endDateField = '';
            
            chartType = '';
            controlType = '';

            lowerThreshold = 0.0;
            maxResults = 0;
            comparisonOperator = '=';
            aggregateFunction = '';
            aggregateField = '';
            forceValues = new String[]{};

            headers = '';
            
            listHeaders = new STring[]{};
            listFormat = '';
        }
    } // ReportInput

    public class ReportOutput
    {
      public String[] chartsData {get; set;}
      public ReportInput[] inputData {get; set;}

      public ReportOutput()
      {
        chartsData = new String[]{};
        inputData = new ReportInput[]{};
      }

      public ReportOutput(ReportInput inputs)
      {
        chartsData = new String[]{};
        inputData = new ReportInput[]{inputs};
      }

      public ReportOutput(ReportInput inputs, String chartDt)
      {
        chartsData = new String[]{chartDt};
        inputData = new ReportInput[]{inputs};
      }

      public ReportOutput(ReportInput[] inputs, String[] chartDt)
      {
        chartsData = chartDt;
        inputData = inputs;
      }

    }

    public class TrendOutput
    {
      public Date[] xLabels {get; set;}
      public Integer[] opened {get; set;}
      public Integer[] closed {get; set;}
      public Integer[] truth {get; set;}
      public Integer[] cumulative {get; set;}
      public Integer[] net {get; set;}

      public TrendOutput()
      {
        xLabels = new Date[]{};
        opened = new Integer[]{};
        closed = new Integer[]{};
        truth = new Integer[]{};
        cumulative = new Integer[]{};
        net = new Integer[]{};
      }

    }

    public class FilterOutput
    {
      public String[] labels {get; set;} // value of aggregates
      public Integer[] counts {get; set;} // number of matches
      public Double[] values {get; set;} // aggregateFunction of aggegrateField
      public String[] colors {get; set;} // NOT USED AT THE MOMENT

      public FilterOutput()
      {
        labels = new String[]{};
        counts = new Integer[]{};
        values = new Double[]{};
        colors = new String[]{};
      }
      
      public void sort(Integer maxSize)
      {
          if (maxSize == null || maxSize == 0 || maxSize > this.values.size())
          {
              maxSize = this.values.size();
          }
          if (maxSize == 0)
          {
              return;
          }
          Boolean sortColors = (this.colors.size() == this.values.size());
          
          FilterOutput nxt = new FilterOutput();
          
          while (nxt.values.size() <= maxSize && this.labels.size() > 0)
          {
              Integer ts = this.values.size();
              
              Double nextVal = 0;
              Integer nextNdx = 0;
              for (Integer ndx = 0; ndx < ts; ndx++)
              {
                  if ((this.values[ndx] >= nextVal))
                  {
                      nextNdx = ndx;
                      nextVal = this.values[ndx];
                  }
              }
              nxt.labels.add(this.labels.remove(nextNdx));
              nxt.counts.add(this.counts.remove(nextNdx));
              nxt.values.add(this.values.remove(nextNdx));
              if (sortColors)
              {
                  nxt.colors.add(this.colors.remove(nextNdx));
              }
          }
          this.labels = nxt.labels;
          this.counts = nxt.counts;
          this.values = nxt.values;
          this.colors = nxt.colors;
      }
    }

    public class ListOutput
    {
      public String[] fieldList {get; set;}
      public String[] labelList {get; set;}
      public List<List<String>> recordData {get; set;}

      public ListOutput()
      {
        fieldList = new String[]{};
        labelList = new String[]{};
        recordData = new List<List<String>>();
      }

    }

    public class AdHocOutput
    {
      public String[] xLabels {get; set;}
      public Integer[] xValues {get; set;}
        public Double[] yValues {get; set;}

      public AdHocOutput()
      {
        xLabels = new String[]{};
        xValues = new Integer[]{};
        yValues = new Double[]{};
      }
    }

    public class filterFilter
    {
      String object_type {get; set;}
      String field {get; set;}
      String operator {get; set;}

      public filterFilter(String o, String f, String op)
      {
        object_type = o;
        field = f;
        operator = op;
      }
    }

    public class filterEntry
    {
      String value {get; set;}
      String label {get; set;}

      public filterEntry(String v, String l)
      {
        value = v;
        label = l;
      }
    }

    public class filterObject
    {
      public string name {get; set;} // 'Filter ABC'
      public string id {get; set;} // 'filterabc' optional (used to shim for existing reports)
      public string type {get; set;} // 'Record List' 'Picklist' 'Record Type' 'Manual' 'Date' 'DateTime-Local' 'Text' 'Number' 'Recency' 'Toggle', 'Button'
      public string object_type {get; set;} // What object do we query to create the list
      public string field_name {get; set;} // If a picklist, what field should we be pulling entries from
      public string value {get; set;} // What is the filter's value?
      public string label {get; set;} // What displays to the user for each value?
      public string order {get; set;} // What are we ordering the list by (record list only)
      public string filter {get; set;} // What field does this filter?
      public List<filterFilter> filters {get; set;} // List of what field filters, for greater control over application
      public string whereClause {get; set;} // For filtering the Record List entries
      public List<filterEntry> entries {get; set;}

      public filterObject()
      {
        name = '';
        id = '';
        type = '';
        object_type = '';
        field_name = '';
        value = '';
        label = '';
        order = '';
        filter = '';
        filters = new List<filterFilter>();
        whereClause = '';
        entries = new List<filterEntry>();
      }
    }

    public class FilterInput
    {
      public List<filterObject> filterList {get; set;}
      public boolean displayToggles {get; set;}
      public boolean displayButtons {get; set;}
      
      public FilterInput()
      {
        filterList = new List<filterObject>();
        displayToggles = true;
        displayButtons = true;
      }
    }

    public static Object extractField(String fld, SObject objType)
    {
        // split at period, use first part to get sub-object, use second part to get value

        Object retval;
        fld = fld.trim();
        if (fld.contains('.'))
        {
            List<String> train;
            SObject subobj;

            train = fld.split('\\.');

            subobj = objType.getSObject(train.get(0));
            if (subobj != null)
            {
                retval = subobj.get(train.get(1));
            }
            else
            {
                retval = '';
            }
        }
        else
        {
            if (fld.contains(' '))
            {
                fld = fld.split(' ').get(1);
            }
            retval = objType.get(fld);
        }
        return retval;
    }

    public static String soqlInj(String input)
    {
      return soqlInj(input, false);
    }
    public static String soqlInj(String input, Boolean casual)
    {
      if (input == null || input == '')
      {
        return input;
      }
      if (casual)
      {
        return //String.escapeSingleQuotes(
          input.replace(';','')
          //)
          ;
      }
      else
      {
        return //String.escapeSingleQuotes(
        input.replace(';','').replace('(','').replace(')','')
        //)
        ;
      }
    }
    
    public static Date getUTCDate(DateTime dt){
        String utcDt = (dt.format('yyyy-MM-dd HH:mm:ss', 'UTC')).split(' ')[0];
        Date utcDate = Date.valueOf(utcDt);
        return utcDate;
    }

}