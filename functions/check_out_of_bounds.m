function isOut = check_out_of_bounds( border, bounds, type )
isOut = false;

if isequal(type, 'image')
    vleft = combvec(1, 1:bounds(1))';
    vright = combvec(bounds(2), 1:bounds(1))';
    htop = combvec(1:bounds(2), 1)';
    hbottom = combvec(1:bounds(2), bounds(1))';
    
    imborder = [vleft; vright; htop; hbottom];
    
    if sum( ismember(border, imborder, 'rows') ) > 0
        isOut = true;
    end
elseif isequal(type, 'roi')
    if sum( ismember(border, bounds, 'rows') ) > 0
        isOut = true;
    end
end


end

