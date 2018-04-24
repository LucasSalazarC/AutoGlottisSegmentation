classdef pLine < handle
    %PLINE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        line
        XData
        YData
        trailingPoint
        followingPoint
    end
    
    methods
        function obj = pLine(line, trailingPoint, followingPoint)
            if nargin ~= 0
                obj.line = line;
                obj.XData = line.XData;
                obj.YData = line.YData;
                obj.trailingPoint = trailingPoint;
                obj.followingPoint = followingPoint;
            end
        end
        
        function [x,y] = moveLine(obj, x, y)
            obj.line.XData = x;
            obj.line.YData = y;
            obj.XData = x;
            obj.YData = y;
        end
    end
    
end

