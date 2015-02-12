 try
  TimeStampMatrix(:,1) = sscanf(textdata{1,1},'%f:%f:%f');
  catch exception1
    if ~exist('exception1') 
      str_format = '%f:%f:%f'; 
    end
    try
      TimeStampMatrix(:,1) = sscanf(textdata{1,1},'"%f:%f:%f"');
    catch exception2
      if ~exist('exception2')  
        str_format = '"%f:%f:%f"'; 
      end
      try
        TimeStampMatrix(:,1) = sscanf(textdata{1,1},'"%f/%f/%f,%f:%f:%f"');
      catch exception3
        if ~exist('exception3')  
          str_format = '"%f/%f/%f,%f:%f:%f"'; 
        end
        try 
          TimeStampMatrix(:,1) = sscanf(textdata{1,1},'%f/%f/%f,%f:%f:%f');
        catch exception4 
          if ~exist('exception4')  
            str_format ='%f/%f/%f,%f:%f:%f'; 
          end
          try   
            TimeStampMatrix(:,1) = sscanf(textdata{1,1},'%f/%f/%f %f:%f:%f');  
          catch exception5
            if ~exist('exception5')  
              str_format = '%f/%f/%f %f:%f:%f'; 
            end
            try
              TimeStampMatrix(:,1) = sscanf(textdata{1,1},'"""%f/%f/%f,%f:%f:%f"""');
            catch exception6
              if ~exist('exception6')  
                str_format = '"""%f/%f/%f,%f:%f:%f"""'; 
              end
            end
          end
        end
      end  
    end
  end


for i=2:length(textdata)
  TimeStampMatrix(:,i) = sscanf(textdata{i,1},str_format);
end