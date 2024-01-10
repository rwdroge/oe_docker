/*------------------------------------------------------------------------
    File        : Properties
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : 
    Created     : 
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

routine-level on error undo, throw.

class util.Properties :

    DEFINE PRIVATE STREAM    m_propStream.

    define private temp-table m_properties  no-undo
                                            field propName  as character 
                                            field propValue as character 
                                            index idxName   is unique primary propName.


    /*------------------------------------------------------------------------------
        Purpose:                                                                        
        Notes:                                                                        
    ------------------------------------------------------------------------------*/

    constructor public Properties (  ):
         super ().

    end constructor.

    constructor public Properties ( input p_path as character ):
         super ().
		 
		        if ( ? = p_path or "" = p_path ) then
            undo, throw new Progress.Lang.AppError("Invalid properties file path", 1).

         load(p_path).

    end constructor.

    destructor public Properties ( ):

    end destructor.

    /*------------------------------------------------------------------------------
        Purpose:                                                                        
        Notes:                                                                        
    ------------------------------------------------------------------------------*/


    method public character GetCharacterProperty( input p_propName as character,
                                                  input p_defValue as character ):

        define variable result as character no-undo.
		
		if ( ? = p_propName or "" = p_propName ) then
            undo, throw new Progress.Lang.AppError("Invalid parameters", 2).

        find first m_properties where m_properties.propName = p_propName no-error. 
        if ( available m_properties ) then
            result = m_properties.propValue.
        else do:
            if ( ? = p_defValue  ) then
                undo, throw new Progress.Lang.AppError("Invalid parameters", 3).
            else 
                 result = p_defValue.
        end.

        return result.


    end method. /*    CHARACTER  */

    /*------------------------------------------------------------------------------
        Purpose:                                                                        
        Notes:                                                                        
    ------------------------------------------------------------------------------*/


    method public logical GetLogicalProperty( input p_propName as character,
                                              input p_defValue as logical ):

        define variable result      as logical initial no no-undo.
        define variable convert     as logical initial no no-undo. 
        define variable tmp         as character initial "" no-undo. 

        if ( ? = p_propName or "" = p_propName ) then
            undo, throw new Progress.Lang.AppError("Invalid parameters", 4).

        find first m_properties where propName = p_propName no-error. 
        if ( available m_properties and "" <> m_properties.propValue ) then
            tmp = lc(m_properties.propValue).

        if ( "" = tmp ) then do:
            if ( ? = p_defValue  ) then
                undo, throw new Progress.Lang.AppError("Invalid parameters",5).
            else 
                result = p_defValue.
        end. else do:
            if ( tmp begins "t" or
                 tmp begins "y" or
                 tmp begins "1" ) then
                result = yes.
        end.

    
        return result.

    end method. /*    CHARACTER  */





    /*------------------------------------------------------------------------------
        Purpose:                                                                        
        Notes:                                                                        
    ------------------------------------------------------------------------------*/

    method public logical Load ( input p_path as character  ):

        define variable result          as logical initial no no-undo.
        define variable propFilePath    as character no-undo. 

        message "Loading properties from file:" p_path.
		
        propFilePath = search(p_path).
        if ( ? <> propFilePath ) then do:

            message "Opening properties file:" propFilePath.
            input STREAM m_propStream FROM VALUE(propFilePath).

            message "Loading properties file:" propFilePath.
            repeat :
                create m_properties.
                import stream m_propStream delimiter "=" m_properties no-error.
            end.

            input STREAM m_propStream CLOSE.

            for each m_properties :
                message "Loaded property" m_properties.propName "with value:" m_properties.propValue.
            end.
        end. else do:
            message "No properties file to load:" p_path.
        end.

        return result.

        catch e as Progress.Lang.Error:
            message "Error in properties load: " e:GetMessage(1).
        end catch.

        finally:
            input STREAM m_propStream CLOSE.
        end finally.

    end method. /*    LOGICAL INITIAL NO */
    
    
    
end class.

